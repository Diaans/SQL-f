create database final_p;
select * from customer_info;

update customer_info set Gender = null where Gender = '';
update customer_info set Age = null where Age = '';
alter table customer_info modify Age int null;

create table Transactions
(date_new date,
Id_check int,
Id_client int,
Count_products decimal(10,3),
Sum_payment decimal(10,2));

show variables like 'secure_file_priv';

load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS.csv"
into table Transactions
fields terminated by ','
lines terminated by '\n'
ignore 1 rows;

select * from Transactions;

# Клиенты с непрерывной историей (каждый месяц с 06.2015 по 05.2016)
SELECT ID_client FROM (SELECT ID_client, DATE_FORMAT(date_new, '%Y-%m') AS mon
  FROM Transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
  GROUP BY ID_client, mon
) t
GROUP BY ID_client
HAVING COUNT(DISTINCT mon) = 12;

# По каждому клиенту: средний чек, среднее в месяц, кол-во операций
SELECT ID_client,
  COUNT(*) AS total_operations,
  AVG(Sum_payment) AS avg_check,
  SUM(Sum_payment)/12 AS avg_monthly_sum
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client;

# Месячный срез: средний чек, операций, клиентов
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  AVG(Sum_payment) AS avg_check,
  COUNT(*) AS total_ops,
  COUNT(DISTINCT ID_client) AS active_clients
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

# Доли операций и сумм по месяцам
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  COUNT(*) AS ops,
  SUM(Sum_payment) AS total_amount,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Transactions 
                            WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'), 2) AS percent_ops,
  ROUND(SUM(Sum_payment) * 100.0 / (SELECT SUM(Sum_payment) FROM Transactions 
                                    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'), 2) AS percent_amount
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

# Распределение по полу (Gender): M/F/NA + доля трат
SELECT 
  DATE_FORMAT(t.date_new, '%Y-%m') AS month,
  c.Gender,
  COUNT(*) AS ops,
  SUM(t.Sum_payment) AS amount_sum,
  ROUND(SUM(t.Sum_payment) * 100.0 / (
    SELECT SUM(Sum_payment) FROM Transactions WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
  ), 2) AS percent_spending
FROM Transactions t
JOIN customer_info c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month, c.Gender
ORDER BY month, c.Gender;

#Возрастные группы (шаг 10 лет + NA): сумма и кол-во
SELECT
CASE 
    WHEN Age IS NULL THEN 'NA'
    ELSE CONCAT(FLOOR(Age / 10) * 10, '-', FLOOR(Age / 10) * 10 + 9)
  END AS age_group,
  COUNT(*) AS ops,
  SUM(Sum_payment) AS total_spent
FROM Transactions t JOIN customer_info c ON t.ID_client = c.Id_client
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY age_group
ORDER BY age_group;

#Поквартальная статистика по возрастным группам
SELECT 
  QUARTER(date_new) AS quarter,
  CASE 
    WHEN Age IS NULL THEN 'NA'
    ELSE CONCAT(FLOOR(Age / 10) * 10, '-', FLOOR(Age / 10) * 10 + 9)
  END AS age_group,
  COUNT(*) AS ops,
  AVG(Sum_payment) AS avg_check,
  ROUND(SUM(Sum_payment) * 100.0 / (SELECT SUM(Sum_payment) 
                                    FROM Transactions 
                                    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'), 2) AS percent_of_total
FROM Transactions t
JOIN customer_info c ON t.ID_client = c.Id_client
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY quarter, age_group
ORDER BY quarter, age_group;