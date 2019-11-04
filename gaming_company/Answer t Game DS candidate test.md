# Answer to Game DS candidate test

## Question 1

I firstly create two test tables in postgresql database which are respectively named customer and transaction. I then use these two tables to test my queries for the two questions.

```sql
CREATE TABLE customer (
    id SERIAL PRIMARY KEY,
    name TEXT,
    regdate DATE
    )

INSERT INTO customer
VALUES (1, 'JACK', '2018-12-01'), (2, 'TOM', '2019-01-01'), (3, 'Kite', '2019-04-03'), (4, 'Bob', '2019-05-30'), (5, 'Susan', '2019-06-30'), (6, 'Mary', '2020-01-01'), (7, 'Ross', '2020-03-07')

CREATE TABLE transaction (
    id SERIAL PRIMARY KEY ,
    customerid INTEGER REFERENCES customer,
    timestamp timestamp
)

INSERT INTO transaction
VALUES (1, 2, '2019-03-04 12:45'), (2, 3, '2019-04-07 13:47'), (3, 3, '2019-04-08 14:30'), (4, 2, '2019-03-09 23:22'),
       (5, 2, '2019-03-20 13:21'), (6, 2, '2019-04-30 11:01'), (7, 3, '2019-04-09 10:38'), (8, 4, '2019-12-30 20:38'),
       (9, 4, '2019-12-30 21:43'), (10, 5, '2020-01-02 22:30'), (11, 1, '2020-01-05 10:00'), (12, 1, '2021-03-04 13:45')
```

### 1. All customers with no transactions.

```sql
SELECT 
	id
FROM 
	customer
WHERE 
	customer.id 
NOT IN (    
    SELECT           
    	customerid    
    FROM
    	transaction)
```

### 2. For each customer output mean and maximum number of days between two consecutive transactions. Then Return '-1' for customers with no or only one transaction output.

Here I use two methods to do this task.

* Method 1

  ```sql
  -- create a view that is an extension of transaction window but have the row number for each customerid.
  CREATE VIEW transaction_ext AS (
      SELECT id, customerid, "timestamp", row_number() over (PARTITION BY customerid order by id) AS rnum
      FROM transaction order by id
  )
  ```

  ```sql
  -- create a second view that will return the customerid, mean and maximum number of days between two consecutive transactions. It is saved as a second view since the next sub-question can make use of this view.
  CREATE VIEW temp_table as (
      SELECT
             t1.customerid,
             AVG(DATE_PART('day', t1.timestamp - t2.timestamp)) AS avg_interval,
             MAX(DATE_PART('day', t1.timestamp - t2.timestamp)) AS max_interval,
             MIN(date_part('day', t1.timestamp - t2.timestamp)) AS min_interval
      FROM
            transaction_ext t1
      JOIN
            transaction_ext t2
      ON
      -- joining on the two same transaction_ext tables by their customerid and when
      -- the row number of the first transaction_ext table equals 1 + the row number of 
      -- the second transaction_ext table. In this way, the difference in two
      -- consecutive transactions can be calculated. 
            t1.customerid = t2.customerid and t1.rnum = t2.rnum + 1
      GROUP BY
            t1.customerid)
  ```

  ```sql
  -- output the mean and maximum for the customerid with at least two transactions
  SELECT
        *
  FROM
        temp_table
  ```

  ```sql
  -- output -1 for the customerid without or only 1 transaction
  SELECT
        id, -1
  FROM
        customer
  WHERE
        id NOT IN (
            SELECT
                  customerid
            FROM
                  temp_table
          )
  ```

  

* Method 2

  ```sql
  -- Directly make use of the lag function to calculate the days between two consecutive transactions for each customer.
  CREATE VIEW temp1_table as (
      SELECT
      customerid,
      date_part('day', timestamp - lag(timestamp) OVER (PARTITION BY customerid ORDER BY id)) as adj_interval
  FROM
      transaction
  ORDER BY
      id
  )
  ```

  ```sql
  -- output the mean and maximum for the customerid with at least two transactions
  SELECT
      customerid,
      AVG(adj_interval) as mean_interval,
      MAX(adj_interval) as max_interval
  FROM
      temp1_table
  GROUP BY
      customerid
  ORDER BY
      customerid
  ```

  ```sql
  -- output -1 for the customerid without or only 1 transaction
  SELECT
      id, -1
  FROM
      customer
  WHERE
      id
  NOT IN (
      SELECT
          customerid
      FROM
          temp1_table
          )
  ```

## Question 2

Assume applicant's score in two tests (SQL and R/Python) are **independently uniformly**  distributed random variables between 0 and 100. Find

### 1. the correlation between SQL and R/Python scores of all applicants.

Because applicant's score are independently distributed, the correlation is 0. 
$$
\text{If variable X is indepdent of Y, then }E(XY)=E(X)\cdot E(Y)\\
\begin{aligned}
\rho(X,Y) &= \frac{Cov(X, Y)}{\sigma(X)\cdot\sigma(Y)}\\
&=\frac{E(XY) - E(X)E(Y)}{\sigma{X}\cdot\sigma{Y}}\\
&=0
\end{aligned}
$$

### 2. the correlation between SQL and R/Python scores of applicants who passed the test.

Firstly, let us derive the correlation analytically.

For those who passed the test, we are basically concerning the uniform distribution of 
$$
X, Y \text{ where } X + Y > 100 \text{ and } 100>X>0 \text{ and }100>Y>0 
$$
We know that they are distributed uniformly in the shaded triangle area as the plot below shows.

 ```python
import matplotlib.pyplot as plt 
import numpy as np
%matplotlib inline
from matplotlib.path import Path
from matplotlib.patches import PathPatch


fig = plt.figure() 
ax = fig.add_subplot(111, aspect='equal') 
path = Path([[100,0],[100,100],[0,100],[100,0]])
patch = PathPatch(path, facecolor='none')
ax.add_patch(patch) 
Z, Z2 = np.meshgrid(np.linspace(0,1), np.linspace(0,1))
im = plt.imshow(Z-Z2, interpolation='bilinear', cmap=plt.cm.RdYlGn,
                origin='upper', extent=[0, 1, 0, 1],
                clip_path=patch, clip_on=True)
im.set_clip_path(patch)
ax.set_xlim((0,1)) 
ax.set_ylim((0,1)) 
plt.show()
 ```

![download](/home/qc/Documents/download.png)

We can derive the  probability density function geometrically. Since the area is 5000, then
$$
f(X, Y) = \frac{1}{5000}
$$
We can alternatively derive it mathematically. Note that for simplicity concern, we denote 100 by K in all following analysis.
$$
\begin{aligned}\int_{0}^K\int_{K-y}^{K}c dxdy &=1\\
&= c\int_{0}^{K}x\bigg\rvert_{K-y}^{K}dy\\
&= c\int_{0}^{K}ydy\\
&=c\cdot\frac{1}{2}y^2\bigg\rvert_{0}^{K}\\
&=\frac{K^2c}{2}
\end{aligned}
$$
therefore we get
$$
f(X, Y) = c = \frac{2}{K^2}
$$
We can then derive the marginal probability density function for X. (Y is symmetric to X so we only need to derive one).
$$
\begin{aligned}
f(x) &= \int_{K-x}^{K}f(x, y)dy\\
&=c\cdot x
\end{aligned}
$$
we then calculate 
$$
\begin{aligned}
E(X) &= \int_{0}^{K}xf(x)dx\\
&= c\cdot\frac{K^3}{3}\\
&=\frac{2K}{3}
\end{aligned}
$$
and
$$
\begin{aligned}
E(X^2) &= \int_{0}^{K}x^2f(x)dx\\
&=c\cdot\frac{K^4}{4}\\
&=\frac{K^2}{2}
\end{aligned}
$$
and therefore,
$$
\begin{aligned}
\sigma(X) &= \sqrt{E(X^2) - (E(X))^2}\\
&=\sqrt{\frac{K^2}{18}}
\end{aligned}
$$


and
$$
\begin{aligned}
E_{XY} &= \int_{0}^{K}\int_{K-y}^{K}xyf(x,y)dxdy\\
&=c\int_{0}^{K}y\cdot\frac{x^2}{2}\bigg\rvert_{K-y}^{K}dy\\
&=c\int_{0}^{K}y\cdot(\frac{K^2}{2} - \frac{(K-y)^2}{2})dy\\
&=c\cdot\int_0^Ky\cdot(Ky-\frac{y^2}{2})dy\\
&=cK\cdot\frac{y^3}{3}\bigg\rvert_0^K-c\cdot \frac{y^4}{8}\bigg\rvert_0^K\\
&=\frac{5cK^4}{24}\\
&=\frac{5K^2}{12}
\end{aligned}
$$
Finally, we can calculate the correlation
$$
\begin{aligned}
\rho(X,Y) &= \frac{E(XY) - E(X)E(Y)}{\sigma{(X)}\cdot\sigma{(Y)}}\\
&=\frac{-\frac{K^2}{36}}{\frac{K^2}{18}}\\
&=-\frac{1}{2}
\end{aligned}
$$
We can simulate in R and verify the above analysis.

```R
set.seed(42)
output_X <- c()
output_Y <- c()

for (counter in 1:1e6) {
    X <- runif(1, 0, 100)
    Y <- runif(1, 0, 100)
    if (X + Y > 100) {
        output_X <- append(output_X, X)
        output_Y <- append(output_Y, Y)
    }
}

print(cor(output_X, output_Y))
```

And the result we get is -0.50046, very close to -0.5.

##  Question 3

A gaming company is developing a new feature called parallel-donkeys. To test the performance of the feature a A/B test is running on randomly selected players.

Parallel-donkeys went viral and the most loyal and the most valuable players, who were in the control group before, are moved from the control group to the test group.

### 1. Do you expect the relative performance of Test and Control groups to change? 

Yes. Let use the money spent on the feature as the key metrics to evaluate their performance. Then when the most loyal and valuable players moved into the test group, the money spent on the test group is inevitably increased because of them. It is a noisy variable that will affect our judgement on the feature itself.

For example, suppose originally both test group and control group have 2 loyal/valuable players and 2 normal players. And intrinsically loyal/valuable players will spend $15 more than the normal player. Such difference is offset because of such (random) grouping. Any further difference can be attributed to the feature. If test group on average spend $10 more (than the control group), such effect size is unbiased. However, if both 2 loyal/valuable players move into the test group, intrinsically the test group should have spent $40 dollars (since there are 4 loyal/valuable players in test group while 0 in control group). If we still assume test and control group are equal and observe the test group on average spend $10 more, we may erroneously arrive at an answer that the feature is functioning great. But in fact,  even without the feature, the test group should still spend $15*4/6 = $10 dollars more than the control group. In summary, it is difficult to tell whether the feature is actually working or not.

### 2. If yes, is there a way to correct for the change in test and control groups?

We can use regression analysis by including a dummy variable as a second regressor. Such dummy variable is 0 if normal customer and 1 if loyal/valuable customer.

Below is an example to show how the change can be corrected.

```R
player_normal <- rep(0, 1000)
player_loyal <- rep(1, 20)
player_control <- rep(0, 500)
player_test <- rep(1, 520)

Y_normal <- rnorm(1000, 50, 5)
Y_loyal <- rnorm(20, 2000, 200)

# suppose an extreme case where all loyal players are in the test_group
Y <- c(Y_normal, Y_loyal)
X_feature <- c(player_control, player_test)
X_noisy <- c(player_normal, player_loyal)
data <- cbind(Y, X_feature, X_noisy)
print(t.test(Y~X_feature, data = data))

library(dplyr)
data_df <- data_frame(data)
# If use anova function, then the summary provides Type I sequential SS not the default
# Type III marginal SS. In a nonorthogonal design with more than one explanatory variables
# the oder will matter! In order to filter out the sequential impact, we use the summary
# from glm model directly.
model <- glm(Y~X_feature*X_noisy, data=data_df)
print(summary(model))
```

And the output for the test without correction is:

```R
	Welch Two Sample t-test

data:  Y by X_feature
t = -4.5823, df = 519.21, p-value = 5.767e-06
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 -109.60465  -43.82535
sample estimates:
mean in group 0 mean in group 1 
       49.75241       126.46741 

```

the output for the test with correction is:

```R

Call:
glm(formula = Y ~ X_feature * X_noisy, data = data_df)

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-361.22    -3.54     0.09     3.83   413.67  

Coefficients: (1 not defined because of singularities)
                   Estimate Std. Error t value Pr(>|t|)    
(Intercept)         49.7524     1.1349  43.838   <2e-16 ***
X_feature            0.7664     1.6050   0.478    0.633    
X_noisy           1974.6627     5.7869 341.228   <2e-16 ***
X_feature:X_noisy        NA         NA      NA       NA    
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

(Dispersion parameter for gaussian family taken to be 644.0121)

    Null deviance: 77141507  on 1019  degrees of freedom
Residual deviance:   654960  on 1017  degrees of freedom
AIC: 9496.7

Number of Fisher Scoring iterations: 2
```

For my test data, I don't differentiate the key performance metrics between control group and test group at all. Without correction for the changes, we can see that the difference is statistically significant showing that the feature works very well. While after including the additional variable and re-run the regression, it shows that such difference caused by the feature is not statically significant. The change has been corrected.

## Question 4. 

Write a function in R or Python which takes a vector of length L consisting only of 0s and 1s as input and return the largest number of consecutive 1s from the vector as an integer, e.g. the function taks [1, 1, 0, 1, 1, 1, 0, 0, 1] and returns 3.

### answer

I shall provide the Python code as below.

```python
def counter_f(vec):
    counter = 0
    counter_max = 0
    for itera, i in enumerate(vec):
        if i == 1:
            counter += 1
            if itera == len(vec) - 1 and counter > counter_max:
                counter_max = counter
        else:
            if counter > counter_max:
                counter_max = counter
            counter = 0
    return counter_max
```



20 unit tests.

```python
random.seed(42)
data = list()
for counter in range(0, 20):
 data.append([random.randint(0, 1) for _ in range(0, 10)])
```

The data list are:

```python
[[0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
 [0, 0, 0, 0, 0, 0, 1, 0, 1, 1],
 [0, 0, 1, 1, 1, 0, 0, 1, 0, 0],
 [1, 0, 1, 1, 1, 0, 1, 0, 1, 0],
 [1, 1, 0, 0, 0, 0, 1, 0, 0, 0],
 [1, 1, 1, 1, 0, 1, 1, 0, 1, 0],
 [0, 0, 0, 1, 1, 1, 0, 1, 0, 0],
 [0, 1, 1, 1, 0, 0, 1, 0, 1, 1],
 [1, 0, 1, 0, 0, 1, 1, 1, 1, 0],
 [0, 1, 0, 0, 0, 0, 0, 1, 0, 1],
 [1, 1, 1, 0, 0, 1, 1, 0, 1, 1],
 [0, 1, 0, 1, 0, 0, 1, 0, 0, 1],
 [0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
 [0, 0, 0, 1, 0, 0, 0, 1, 0, 1],
 [1, 0, 0, 1, 1, 1, 1, 1, 0, 0],
 [0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
 [0, 0, 1, 0, 0, 1, 1, 0, 0, 1],
 [0, 1, 1, 0, 0, 0, 1, 1, 1, 1],
 [1, 0, 0, 0, 1, 1, 0, 0, 0, 0],
 [1, 0, 1, 0, 1, 1, 0, 0, 1, 0]]
```

And carry out tests on these unit tests.

```python
[counter_f(x) for x in data]
```

The results are:

```py
[1, 2, 3, 3, 2, 4, 3, 3, 4, 1, 3, 1, 2, 1, 5, 1, 2, 4, 2, 2]
```





