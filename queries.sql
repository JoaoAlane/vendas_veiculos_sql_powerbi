-- Query 1 - Funil de conversão completo em 5 estágios
select 'Visitou a página' as etapa, 1 as ordem, count(*) as "quantidade"
from sales.funnel where visit_page_date is not null
union all
select 'Adicionou ao carrinho', 2, count(*)
from sales.funnel where add_to_cart_date is not null
union all
select 'Iniciou checkout', 3, count(*)
from sales.funnel where start_checkout_date is not null
union all
select 'Finalizou checkout', 4, count(*)
from sales.funnel where finish_checkout_date is not null
union all
select 'Pagou', 5, count(*)
from sales.funnel where paid_date is not null
order by ordem


-- Query 2 - Vendas e receita por status profissional do cliente
select
	cus.professional_status as status_profissional,
	count(fun.paid_date) as "vendas",
	sum(pro.price * (1+fun.discount)) as "receita (R$)",
	avg(pro.price * (1+fun.discount)) as "ticket_médio (R$)"
from sales.funnel as fun
left join sales.customers as cus
	on fun.customer_id = cus.customer_id
left join sales.products as pro
	on fun.product_id = pro.product_id
where fun.paid_date is not null
group by status_profissional
order by "receita (R$)" desc


-- Query 3 - Volume de vendas vs. receita por marca (top 10)
select
	pro.brand as marca,
	count(fun.paid_date) as "vendas",
	sum(pro.price * (1+fun.discount)) as "receita (R$)",
	avg(pro.price) as "preço_médio (R$)"
from sales.funnel as fun
left join sales.products as pro
	on fun.product_id = pro.product_id
where fun.paid_date is not null
group by marca
order by "receita (R$)" desc
limit 10


-- Query 4 - Faixa de score de crédito x conversão e ticket médio
with faixas as (
	select
		fun.*,
		case
			when cus.score < 300 then '0-299'
			when cus.score < 500 then '300-499'
			when cus.score < 700 then '500-699'
			else '700+'
		end as faixa_score
	from sales.funnel as fun
	left join sales.customers as cus
		on fun.customer_id = cus.customer_id
)
select
	faixas.faixa_score,
	count(*) as "leads",
	count(faixas.paid_date) as "vendas",
	(count(faixas.paid_date)::float / count(*)::float) as "conversão (%)",
	avg(pro.price * (1+faixas.discount)) as "ticket_médio (R$)"
from faixas
left join sales.products as pro
	on faixas.product_id = pro.product_id
group by faixas.faixa_score
order by faixas.faixa_score


-- Query 5 - Top 10 cidades de São Paulo por vendas
select
	cus.city as cidade,
	count(fun.paid_date) as "vendas",
	sum(pro.price * (1+fun.discount)) as "receita (R$)"
from sales.funnel as fun
left join sales.customers as cus
	on fun.customer_id = cus.customer_id
left join sales.products as pro
	on fun.product_id = pro.product_id
where fun.paid_date is not null
	and cus.state = 'SP'
group by cidade
order by "vendas" desc
limit 10


-- Query 6 - Desconto médio por faixa de preço do veículo
select
	case
		when pro.price < 50000 then 'Até R$ 50k'
		when pro.price < 100000 then 'R$ 50k-100k'
		when pro.price < 200000 then 'R$ 100k-200k'
		else 'Acima de R$ 200k'
	end as faixa_preco,
	count(fun.paid_date) as "vendas",
	avg(fun.discount) * -1 as "desconto_médio (%)"
from sales.funnel as fun
left join sales.products as pro
	on fun.product_id = pro.product_id
where fun.paid_date is not null
group by faixa_preco
order by min(pro.price)