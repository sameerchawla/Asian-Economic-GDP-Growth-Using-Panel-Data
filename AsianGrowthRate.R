# GDP Growth - Emerging Asia (1995-2024)
# MSc Economics, GIPE | 2025


# ---- 1. PACKAGES -------------------------------------------------------------

library(WDI)
library(dplyr)
library(ggplot2)
library(corrplot)
library(plm)
library(lmtest)

dir.create("figures", showWarnings = FALSE)


# ---- 2. DATA -----------------------------------------------------------------

countries <- c("IN", "CN", "ID", "TH", "MY", "PH", "VN", "BD", "PK", "LK")

data_raw <- WDI(
  country = countries,
  indicator = c(
    gdp_growth = "NY.GDP.MKTP.KD.ZG",
    inflation  = "FP.CPI.TOTL.ZG",
    fdi        = "BX.KLT.DINV.WD.GD.ZS",
    trade      = "NE.TRD.GNFS.ZS",
    investment = "NE.GDI.TOTL.ZS"
  ),
  start = 1995,
  end   = 2024
)

data_clean <- data_raw %>%
  select(country, iso2c, year, gdp_growth, inflation, fdi, trade, investment) %>%
  arrange(country, year) %>%
  na.omit()

nrow(data_clean)


# ---- 3. DESCRIPTIVE STATISTICS -----------------------------------------------

summary(data_clean[, c("gdp_growth", "inflation", "fdi", "trade", "investment")])

# average by country
data_clean %>%
  group_by(country) %>%
  summarise(
    avg_growth     = round(mean(gdp_growth), 2),
    avg_inflation  = round(mean(inflation),  2),
    avg_fdi        = round(mean(fdi),        2),
    avg_investment = round(mean(investment), 2)
  ) %>%
  arrange(desc(avg_growth))

# correlation matrix
cor_matrix <- cor(data_clean[, c("gdp_growth", "inflation", "fdi", "trade", "investment")])
cor_matrix


# ---- 4. REGRESSION -----------------------------------------------------------

# baseline OLS
model_ols <- lm(gdp_growth ~ inflation + fdi + log(trade) + investment,
                data = data_clean)
summary(model_ols)

# fixed effects
model_fe <- plm(gdp_growth ~ inflation + fdi + log(trade) + investment,
                data  = data_clean,
                index = c("country", "year"),
                model = "within")
summary(model_fe)

# random effects
model_re <- plm(gdp_growth ~ inflation + fdi + log(trade) + investment,
                data  = data_clean,
                index = c("country", "year"),
                model = "random")
summary(model_re)


# ---- 5. DIAGNOSTIC TESTS -----------------------------------------------------

# hausman test - p < 0.05 means use fixed effects
phtest(model_fe, model_re)

# heteroskedasticity
bptest(model_ols)

# serial correlation
pbgtest(model_fe)

# robust standard errors
coeftest(model_fe, vcov = vcovHC(model_fe, type = "HC1"))


# ---- 6. FIGURES --------------------------------------------------------------

# growth over time
ggplot(data_clean, aes(x = year, y = gdp_growth, color = country)) +
  geom_line(linewidth = 1) +
  theme_minimal() +
  labs(title = "GDP Growth Trends (1995-2024)",
       x = "Year", y = "GDP Growth (%)", color = "Country")
ggsave("figures/gdp_trends.png", width = 9, height = 5)

# inflation vs growth
ggplot(data_clean, aes(x = inflation, y = gdp_growth)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  theme_minimal() +
  labs(title = "Inflation vs GDP Growth",
       x = "Inflation (%)", y = "GDP Growth (%)")
ggsave("figures/inflation_growth.png", width = 7, height = 5)

# fdi vs growth
ggplot(data_clean, aes(x = fdi, y = gdp_growth)) +
  geom_point(color = "darkgreen", alpha = 0.7) +
  geom_smooth(method = "lm", color = "black", se = FALSE) +
  theme_minimal() +
  labs(title = "FDI vs GDP Growth",
       x = "FDI (% of GDP)", y = "GDP Growth (%)")
ggsave("figures/fdi_growth.png", width = 7, height = 5)

# average growth by country
data_clean %>%
  group_by(country) %>%
  summarise(avg_growth = mean(gdp_growth)) %>%
  ggplot(aes(x = reorder(country, avg_growth), y = avg_growth)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Average GDP Growth by Country",
       x = NULL, y = "Avg Growth (%)")
ggsave("figures/avg_growth.png", width = 7, height = 5)

# correlation plot
png("figures/correlation.png", width = 600, height = 600)
corrplot(cor_matrix, method = "color", type = "upper",
         tl.col = "black", tl.srt = 45)
dev.off()

getwed()
getwd()
getwd()
list.files("figures")
