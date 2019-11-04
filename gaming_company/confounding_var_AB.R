library(dplyr)
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
data_df <- data_frame(data)
print(t.test(Y~X_feature, data = data))
model0 <- lm(Y~X_feature, data=data_df)
summary(model0)

data_df <- data_frame(data)
model <- lm(Y~X_feature*X_noisy, data=data_df)
print(summary(model))

model2 <- aov(Y ~ X_feature + X_noisy, data=data_df)
print(summary(model2))
model3 <- aov(Y ~ X_noisy + X_feature, data=data_df)
print(summary(model3))

# because the sequence matters a lot and anova summary uses the sequential SS by default, we should avoid it and uses Anova() instead by setting type=3.
Anova(model3, type=3)
