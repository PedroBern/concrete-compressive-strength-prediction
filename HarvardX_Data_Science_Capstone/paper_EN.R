# Install libraries, if not already installed
if(!require(tidyverse)) install.packages("tidyverse")
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(caret)) install.packages("caret")
if(!require(gdata)) install.packages("gdata")
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(dplyr)) install.packages("dplyr")
if(!require(tidyr)) install.packages("tidyr")
if(!require(pastecs)) install.packages("pastecs")
if(!require(factoextra)) install.packages("factoextra")
if(!require(reshape2)) install.packages("reshape2")
if(!require(purrr)) install.packages("purrr")
if(!require(questionr)) install.packages("questionr")

# Load libraries
library(tidyverse)
library(caret)
library(ggplot2)
library(knitr)
library(kableExtra)
library(dplyr)
library(tidyr)
library(gdata)
library(reshape2)
library(cowplot)
library(pastecs)
library(factoextra)
library(purrr)
library(gridExtra)
library(questionr)


# Data download
url_base <- "https://archive.ics.uci.edu"
url <-  "/ml/machine-learning-databases/concrete/compressive/Concrete_Data.xls"
download.file(paste0(url_base, url), "data.xls")
dat <- read.xls("data.xls")
n_inicial_samples <- nrow(dat)
colnames(dat)
		

# Renaming the columns
colnames(dat) <- c(
	"cement",
	"blast_furnace_slag",
	"fly_ash",
	"water",
	"superplasticizers",
	"coarse_aggregate",
	"fine_aggregate",
	"day",
	"mpa"
)
dat$id <- seq.int(nrow(dat))


# Reordering the data
col_order <- c(
	"id",
	"cement",
	"blast_furnace_slag",
	"fly_ash",
	"water",
	"superplasticizers",
	"coarse_aggregate",
	"fine_aggregate",
	"day",
	"mpa"
)
dat <- dat[, col_order]
		
		
# Removing duplicated samples
dat <- dat[!duplicated(select(dat, -c(id))),]
		
		
# Data cleaning
# keep only samples with MPa for 28 days
dat <- dat %>%
	group_by(
		cement,
		blast_furnace_slag,
		fly_ash,
		water,
		superplasticizers,
		coarse_aggregate,
		fine_aggregate,
	) %>%
	filter("28" %in% day) %>%
	mutate(id = id[which.min(id)]) %>%
	ungroup() %>%
	group_by(id, day) %>%
	mutate(mpa = mean(mpa)) %>%
	ungroup()
dat <- dat[!duplicated(select(dat, -c(id))),]
dat$id <- factor(dat$id)


# Joining 90, 91 and 100 days data
ind_90 <- dat$id[which(dat$day == "90")]
ind_91 <- dat$id[which(dat$day == "91")]
ind_100 <- dat$id[which(dat$day == "100")]
dat <- dat %>%
	ungroup() %>%
	mutate(day = ifelse(day %in% c(91, 90), 100, day))
		

# Removing ages with frequency lower than 50
dat <- dat[dat$day %in% c(3, 7, 14, 28, 56, 100),]
		

# Data reorganization
dat <- dat %>%
	group_by_at(vars(-mpa)) %>%
	mutate(row_id = 1:n()) %>% ungroup() %>%
	spread(day, mpa, sep = "_") %>%
	select(-row_id)


# Adding New features - concrete class and proportions
concrete_class <- function(mpa){
	if (mpa >= 10) {
		s <- as.character(mpa)
		first <- substr(s, start = 1, stop = 1)
		second <- ifelse(substr(s, start = 2, stop = 2) >= 5, 5, 0)
	}
	else {
		first <- ""
		second <- "5"
	}
	paste("C", first, second, sep = "")
}
mix <- function(c, f_ag, c_ag){
	paste(
		1,
		round(f_ag/c, 0),
		round(c_ag/c, 0),
		sep = ":")
}
dat <- dat %>%
	mutate(class = sapply(day_28, concrete_class)) %>%
	mutate(class = as.factor(class)) %>%
	mutate(mix_app = factor(
		mix(cement, fine_aggregate, coarse_aggregate))) %>%
	mutate(`water_/_cement` = water / cement) %>%
	mutate(`fine_aggregate_/_cement` = fine_aggregate/cement) %>%
	mutate(`coarse_aggregate_/_cement` = coarse_aggregate/cement) %>%
	mutate(`fine_aggregate_/_coarse_aggregate` = fine_aggregate/coarse_aggregate) %>%
	mutate(`water_/_coarse_aggregate` = water/coarse_aggregate) %>%
	mutate(`water_/_fine_aggregate` = water/fine_aggregate)
lvl <- levels(dat$class)
dat$class <- factor(
	dat$class,
	levels=c( "C5", sort(lvl[lvl!="C5"], decreasing=F)))


# Machine learning models

# Converting Dummy variables
dummies <- dummyVars( ~ mix_app, data = dat)
dummyDat <- data.frame(predict(dummies, newdata = dat))
dummyDat$id <- dat$id
dat <- dat %>%
	select(-c(mix_app)) %>%
	full_join(., dummyDat)


# Data preparation, creating one dat for each age
names(dat) <- gsub(x = names(dat), pattern = "/", replacement = ".")
dat_3 <- dat %>%
	select(-c("day_7", "day_14", "day_28", "day_56", "day_100")) %>%
	drop_na() %>%
	rename_at("day_3",~"mpa")
dat_7 <- dat %>%
	select(-c("day_3", "day_14", "day_28", "day_56", "day_100")) %>%
	drop_na() %>%
	rename_at("day_7",~"mpa")
dat_14 <- dat %>%
	select(-c("day_3", "day_7", "day_28", "day_56", "day_100")) %>%
	drop_na() %>%
	rename_at("day_14",~"mpa")
dat_28 <- dat %>%
	select(-c("day_3", "day_7", "day_14", "day_56", "day_100")) %>%
	drop_na() %>%
	rename_at("day_28",~"mpa")
dat_56 <- dat %>%
	select(-c("day_3", "day_7", "day_14", "day_28", "day_100")) %>%
	drop_na() %>%
	rename_at("day_56",~"mpa")
dat_100 <- dat %>%
	select(-c("day_3", "day_7", "day_14", "day_28", "day_56")) %>%
	drop_na() %>%
	rename_at("day_100",~"mpa")


# Removing near zero variance columns
nzv_3 <- nearZeroVar(dat_3)
nzv_7 <- nearZeroVar(dat_7)
nzv_14 <- nearZeroVar(dat_14)
nzv_28 <- nearZeroVar(dat_28)
nzv_56 <- nearZeroVar(dat_56)
nzv_100 <- nearZeroVar(dat_100)
dat_3 <- dat_3[,-nzv_3]
dat_7 <- dat_7[,-nzv_7]
dat_14 <- dat_14[,-nzv_14]
dat_28 <- dat_28[,-nzv_28]
dat_56 <- dat_56[,-nzv_56]
dat_100 <- dat_100[,-nzv_100]


# High correlation variables verification
descr_cor_3 <- cor(select(dat_3, -c(mpa, id, class)))
descr_cor_7 <- cor(select(dat_7, -c(mpa, id, class)))
descr_cor_14 <- cor(select(dat_14, -c(mpa, id, class)))
descr_cor_28 <- cor(select(dat_28, -c(mpa, id, class)))
descr_cor_56 <- cor(select(dat_56, -c(mpa, id, class)))
descr_cor_100 <- cor(select(dat_100, -c(mpa, id, class)))
high_cor_3 <- sum(abs(descr_cor_3[upper.tri(descr_cor_3)]) > .999)
high_cor_7 <- sum(abs(descr_cor_7[upper.tri(descr_cor_7)]) > .999)
high_cor_14 <- sum(abs(descr_cor_14[upper.tri(descr_cor_14)]) > .999)
high_cor_28 <- sum(abs(descr_cor_28[upper.tri(descr_cor_28)]) > .999)
high_cor_56 <- sum(abs(descr_cor_56[upper.tri(descr_cor_56)]) > .999)
high_cor_100 <- sum(abs(descr_cor_100[upper.tri(descr_cor_100)]) > .999)


# Test and train data split
reg <- list(
	dat_3 %>% select(-c(mpa, class, id)) %>% mutate(y = dat_3$mpa),
	dat_7 %>% select(-c(mpa, class, id)) %>% mutate(y = dat_7$mpa),
	dat_14 %>% select(-c(mpa, class, id)) %>% mutate(y = dat_14$mpa),
	dat_28 %>% select(-c(mpa, class, id)) %>% mutate(y = dat_28$mpa),
	dat_56 %>% select(-c(mpa, class, id)) %>% mutate(y = dat_56$mpa),
	dat_100 %>% select(-c(mpa, class, id)) %>% mutate(y = dat_100$mpa)
)
reg_seed <- c(
	1111, # 3
	1, # 7
	22, # 14
	11111, # 28
	111, # 56
	11 # 100
)
split_reg <- function(n){
	set.seed(reg_seed[[n]], sample.kind="Rounding")
	createDataPartition(reg[[n]]$y, p = .8, list = F)
}
trainIndex_reg <- lapply(list(1,2,3,4,5,6), split_reg)
gen_dat <- function(n){
	regIndex <- trainIndex_reg[[n]]
	list(train = reg[[n]][regIndex,], test = reg[[n]][-regIndex,])
}
dats_reg <- lapply(list(1,2,3,4,5,6), gen_dat)
names(dats_reg) <- c("d3", "d7", "d14", "d28", "d56", "d100")


# Features selection based on models for each configuration
# Run pre-models with no optimization, but with different set of
# features, in order to select the best combination
data1 <- dats_reg$d28$train # full
data2 <- dats_reg$d28$train[c(1:13, 21)] # no dummy vars
data3 <- dats_reg$d28$train[c(1:7, 21)] # only original variables
data4 <- dats_reg$d28$train[c(8:21)] # only new variables
data5 <- dats_reg$d28$train[c(8:13, 21)] # only new varibels, no dummy vars
test1 <- dats_reg$d28$test # full
test2 <- dats_reg$d28$test[c(1:13, 21)] # no dummy vars
test3 <- dats_reg$d28$test[c(1:7, 21)] # only original variables
test4 <- dats_reg$d28$test[c(8:21)] # only new variables
test5 <- dats_reg$d28$test[c(8:13, 21)] # only new varibels, no dummy vars
# parRF
modelLookup("parRF")
control_parRF <- trainControl(method='repeatedcv',number=10,repeats=5,search='grid')
fit_parRF<- function(data, n) {
	set.seed(1, sample.kind = "Rounding")
	tunegrid_parRF<- expand.grid(mtry = seq(1, length(data), n))
	train(y ~ .,
							data = data,
							preProcess = c("center","scale"),
							method='parRF',
							tuneGrid=tunegrid_parRF,
							trControl=control_parRF)
}

# full
fit_parRF1 <- fit_parRF(data1, 3)
ggplot(fit_parRF1)
min(fit_parRF1$results$RMSE) # 6.26108
p1_parRF1 <- predict(fit_parRF1, newdata = test1)
RMSE(p1_parRF1, test1$y) # 4.887264

# no dummy vars
fit_parRF2 <- fit_parRF(data2, 1)
ggplot(fit_parRF2)
min(fit_parRF2$results$RMSE) # 6.268789
p_parRF2 <- predict(fit_parRF2, newdata = test2)
RMSE(p_parRF2, test2$y) # 4.812994

# only original variables
fit_parRF3 <- fit_parRF(data3, 1)
ggplot(fit_parRF3)
min(fit_parRF3$results$RMSE) # 6.361905
p_parRF3 <- predict(fit_parRF3, newdata = test3)
RMSE(p_parRF3, test3$y) # 5.083467

# only new varibels
fit_parRF4 <- fit_parRF(data4, 1)
ggplot(fit_parRF4)
min(fit_parRF4$results$RMSE) # 8.705984
p_parRF4 <- predict(fit_parRF4, newdata = test4)
RMSE(p_parRF4, test4$y) # 8.083962

# only new varibels, no dummy vars
fit_parRF5 <- fit_parRF(data5, 1)
ggplot(fit_parRF5)
min(fit_parRF5$results$RMSE) # 8.691755
p_parRF5 <- predict(fit_parRF5, newdata = test5)
RMSE(p_parRF5, test5$y) # 7.991537


# Definitive Regression models
# with no dummy vars:
data3 <- dats_reg$d3$train[c(1:13, 22)]
data7 <- dats_reg$d7$train[c(1:12, 19)]
data14 <- dats_reg$d14$train[c(1:13, 21)]
data28 <- dats_reg$d28$train[c(1:13, 21)]
data56 <- dats_reg$d56$train[c(1:13, 22)]
data100 <- dats_reg$d100$train[c(1:13, 23)]
test3 <- dats_reg$d3$test[c(1:13, 22)]
test7 <- dats_reg$d7$test[c(1:12, 19)]
test14 <- dats_reg$d14$test[c(1:13, 21)]
test28 <- dats_reg$d28$test[c(1:13, 21)]
test56 <- dats_reg$d56$test[c(1:13, 22)]
test100 <- dats_reg$d100$test[c(1:13, 23)]

get_trControl <- function(n, r){
	trainControl(method='repeatedcv',number=n,repeats=r,search='grid')
}

trControl3 <- get_trControl(30, 10)
trControl7 <- get_trControl(10, 10)
trControl14 <- get_trControl(30, 10)
trControl28 <- get_trControl(30, 10)
trControl56 <- get_trControl(30, 10)
trControl100 <- get_trControl(10, 10)

get_tuneGrid <- function(data){
	expand.grid(mtry = seq(1, length(data), 1))
}

tuneGrid3 <- get_tuneGrid(data3)
tuneGrid7 <- get_tuneGrid(data7)
tuneGrid14 <- get_tuneGrid(data14)
tuneGrid28 <- get_tuneGrid(data28)
tuneGrid56 <- get_tuneGrid(data56)
tuneGrid100 <- get_tuneGrid(data100)
set.seed(1, sample.kind = "Rounding")

fit_3 <- train(y ~ .,
															data = data3,
															preProcess = c("center","scale"),
															method='parRF',
															tuneGrid=tuneGrid3,
															trControl=trControl3)
p_3 <- predict(fit_3, newdata = test3)
RMSE_test_3 <- RMSE(p_3, test3$y)
RMSE_test_3 # 3.31037
fit_3$bestTune # mtry = 6

set.seed(1, sample.kind = "Rounding")
fit_7 <- train(y ~ .,
															data = data7,
															preProcess = c("center","scale"),
															method='parRF',
															tuneGrid=tuneGrid7,
															trControl=trControl7)
p_7 <- predict(fit_7, newdata = test7)
RMSE_test_7 <- RMSE(p_7, test7$y)
RMSE_test_7 # 4.361987
fit_7$bestTune # mtry = 2

set.seed(1, sample.kind = "Rounding")
fit_14 <- train(y ~ .,
																data = data14,
																preProcess = c("center","scale"),
																method='parRF',
																tuneGrid=tuneGrid14,
																trControl=trControl14)
p_14 <- predict(fit_14, newdata = test14)
RMSE_test_14 <- RMSE(p_14, test14$y)
RMSE_test_14 # 4.620515
fit_14$bestTune # mtry = 13

set.seed(1, sample.kind = "Rounding")
fit_28 <- train(y ~ .,
																data = data28,
																preProcess = c("center","scale"),
																method='parRF',
																tuneGrid=tuneGrid28,
																trControl=trControl28)
p_28 <- predict(fit_28, newdata = test28)
RMSE_test_28 <- RMSE(p_28, test28$y)
RMSE_test_28 # 4.716698
fit_28$bestTune # mtry = 11

set.seed(1, sample.kind = "Rounding")
fit_56 <- train(y ~ .,
																data = data56,
																preProcess = c("center","scale"),
																method='parRF',
																tuneGrid=tuneGrid56,
																trControl=trControl56)
p_56 <- predict(fit_56, newdata = test56)
RMSE_test_56 <- RMSE(p_56, test56$y)
RMSE_test_56 # 5.939163
fit_56$bestTune # mtry = 8

set.seed(1, sample.kind = "Rounding")
fit_100 <- train(y ~ .,
																	data = data100,
																	preProcess = c("center","scale"),
																	method='parRF',
																	tuneGrid=tuneGrid100,
																	trControl=trControl100)
p_100 <- predict(fit_100, newdata = test100)
RMSE_test_100 <- RMSE(p_100, test100$y)
RMSE_test_100 # 5.851088
fit_100$bestTune # mtry = 8

# Results

# Table - Models details
colNames <- c("Model", "mtry", "CV", "Repetitions",
														"RMSE (train)", "RMSE (test)")
caption <- "Regression models results"
day <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
dat_reg_models <- data.frame(
	dia = day,
	mtry = c(fit_3$bestTune$mtry, fit_7$bestTune$mtry, fit_14$bestTune$mtry,
										fit_28$bestTune$mtry, fit_56$bestTune$mtry, fit_100$bestTune$mtry),
	number = c(trControl3$number, trControl7$number, trControl14$number,
												trControl28$number,trControl56$number,trControl100$number),
	repeats = c(trControl3$repeats, trControl7$repeats, trControl14$repeats,
													trControl28$repeats,trControl56$repeats,trControl100$repeats),
	RMSE_train = c(min(fit_3$results$RMSE), min(fit_7$results$RMSE),
																min(fit_14$results$RMSE), min(fit_28$results$RMSE),
																min(fit_56$results$RMSE), min(fit_100$results$RMSE)),
	RMSE_test = c(RMSE_test_3, RMSE_test_7, RMSE_test_14,
															RMSE_test_28, RMSE_test_56, RMSE_test_100)
)
kable(
	dat_reg_models,
	col.names = colNames,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c"
)


# Figure - Models comparison
cap <- "Actual vs Predicted values in each model"
models <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
xlabel <- "Actual (MPa)"
ylabel <- "Predicted (MPa)"
preds <- list(p_3, p_7, p_14, p_28, p_56, p_100)
actuals <- list(test3$y, test7$y, test14$y, test28$y, test56$y, test100$y)
gen_res_df <- function(ind){
	data.frame(actual = actuals[[ind]], pred = preds[[ind]], model = models[[ind]])
}
res_df <- lapply(1:6, gen_res_df)
res_df <- bind_rows(res_df)
res_df$model <- factor(res_df$model,levels=models)
res_df %>%
	ggplot(aes(actual, pred)) +
	facet_wrap(~ model, ncol=3) +
	geom_point(alpha=0.5) +
	theme_bw() +
	geom_abline(slope=1, intercept=0) +
	xlab(xlabel) +
	ylab(ylabel)



# 		```{r table-10, echo=F}
# 		# Results tables of 10 best and worst results
# 		colNames1 = c("Actual", "Predicted", "Error", "","Actual", "Predicted", "Error") 
# 		colNames2 = c("Best 10"=3,"", "Worst 10"=3) 
# 		caption_0 <- "Model of "
# 		get_X <- function(pred, actual, X=10){
# 			diff <- abs(pred - actual)
# 			diff_2 <- pred - actual
# 			ind_min <- which(diff <= max(sort(diff, decreasing = F)[1:X]), arr.ind = T)
# 			ind_max <- which(diff >= min(sort(diff, decreasing = T)[1:X]), arr.ind = T)
# 			df_min <- data.frame(
# 				actual_min=actual[ind_min],
# 				pred_min=pred[ind_min],
# 				diff_min=diff[ind_min],
# 				diff_min_2=diff_2[ind_min]
# 			)
# 			df_max <- data.frame(
# 				actual_max=actual[ind_max],
# 				pred_max=pred[ind_max],
# 				diff_max=diff[ind_max],
# 				diff_max_2=diff_2[ind_max]
# 			)
# 			df_max <- df_max[order(-df_max$diff_max),]
# 			df_min <- df_min[order(df_min$diff_min),]
# 			df_null <- data.frame(null_col = rep(c(""), X))
# 			res <- cbind(df_min,df_null, df_max)
# 			res <- res %>% select(-c(diff_max, diff_min))
# 			rownames(res) <- c()
# 			res
# 		}
# 		gen_kable <- function(ind){
# 			df <- get_X(preds[[ind]], actuals[[ind]])
# 			caption <- paste0(caption_0,models[ind])
# 			kable(
# 				df,
# 				col.names = colNames1,
# 				escape = F,
# 				booktabs = T,
# 				caption = caption,
# 				linesep = "\\addlinespace",
# 				align = "c"
# 			)  %>%
# 				column_spec(4, width = "1cm",) %>%
# 				add_header_above(header = colNames2, line = T, align = "c") %>%
# 				kable_styling(latex_options = c("HOLD_position"))
# 		}
# 		gen_kable(1)
# 		gen_kable(2)
# 		gen_kable(3)
# 		gen_kable(4)
# 		gen_kable(5)
# 		gen_kable(6)
# 		```
# 		
# 		
# 		
# 		# Discussion
# 		The models built present satisfactory results and prove that the compressive strength of concrete can be predicted relatively easily. The alternative adopted to create a model for each set of age proved to be a valid method, managing to stratify to obtain specific results for each set. The studies cited in the introduction using the same dataset have similar results, as expected. The \ref{tab:works-comparison} table presents the results of these works (\ref{show-works-comparison}), and the table \ref{tab:results} presents the values found for easy comparison (\ref{show-results}) .
# 		```{r works-comparison, echo=F}
# 		# Table - Comparison of other works
# 		colNames = c("Author","Year" ,"Algorithm", "RMSE") 
# 		caption <- "Comparison of other works"
# 		works <- data.frame(
# 			autor = c("Pierobon", "Hameed", "Raj","Modukuru" ,"Alshamiri", "Abban"),
# 			ano = c("2018", "2020", "2018","2020" ,"2020", "2016"),
# 			modelo = c("Ensemble com 5 algorítimos", "Artificial Neural Networks", 
# 														"Gradient Boosting Regressor","Random Forest Regressor" ,
# 														"Regularized Extreme Learning Machine",
# 														"Support Vector Machines with Radial Basis Function Kernel"),
# 			RMSE = c("4.150", "4.736", "4.957","5.080","5.508", "6.105")
# 		)
# 		kable(
# 			works,
# 			col.names = colNames,
# 			escape = F,
# 			booktabs = T,
# 			caption = caption,
# 			linesep = "\\addlinespace",
# 			align = "l"
# 		)  %>%
# 			kable_styling(latex_options = c("HOLD_position"))
# 		```
# 		```{r results, echo=F}
# 		# Table - Final results
# 		colNames <- c("Model", "RMSE")
# 		caption <- "Final result"
# 		day <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
# 		dat_reg_models <- data.frame(
# 			dia = day,
# 			RMSE_test = c(RMSE_test_3, RMSE_test_7, RMSE_test_14,
# 																	RMSE_test_28, RMSE_test_56, RMSE_test_100)
# 		)
# 		kable(
# 			dat_reg_models,
# 			col.names = colNames,
# 			escape = F,
# 			booktabs = T,
# 			caption = caption,
# 			linesep = "\\addlinespace",
# 			align = "c"
# 		)  %>%
# 			kable_styling(latex_options = c("HOLD_position"))
# 		```
# 		Following the line of reasoning of this work, it can be performed with different algorithms, the results found here used only one (*Parallel Random Forest*), even though it was theoretically the "best" found, other algorithms can present even better results. Another option is to create an *ensemble* of various algorithms, just like @Pierobon2018, but with the separation of age sets proposed here. In addition, it can be performed with a larger dataset, ideally with the same number of samples in each age set, a more homogeneous distribution of compressive strength, and less variance between samples.
# 		
# 		
# 	
# 		
# 		





















# # Data reorganization
# # dat <- dat %>%
# # 	group_by_at(vars(-mpa)) %>%
# # 	mutate(row_id = 1:n()) %>% ungroup() %>%
# # 	spread(day, mpa, sep = "_") %>%
# # 	select(-row_id)
# 
# 
# # Adding New features - concrete proportions
# dat <- dat %>%
# 	mutate(`water_/_cement` = water / cement) %>%
# 	mutate(`fine_aggregate_/_cement` = fine_aggregate/cement) %>%
# 	mutate(`coarse_aggregate_/_cement` = coarse_aggregate/cement) %>%
# 	mutate(`fine_aggregate_/_coarse_aggregate` = fine_aggregate/coarse_aggregate) %>%
# 	mutate(`water_/_coarse_aggregate` = water/coarse_aggregate) %>%
# 	mutate(`water_/_fine_aggregate` = water/fine_aggregate)
# #
# #
# # # Machine learning models
# #
# # # Converting Dummy variables
# # dummies <- dummyVars( ~ mix_app, data = dat)
# # dummyDat <- data.frame(predict(dummies, newdata = dat))
# # dummyDat$id <- dat$id
# # dat <- dat %>%
# # 	select(-c(mix_app)) %>%
# # 	full_join(., dummyDat)
# 
# 
# # Data preparation, creating one dat for each age
# # names(dat) <- gsub(x = names(dat), pattern = "/", replacement = ".")
# # dat_3 <- dat %>%
# # 	select(-c("day_7", "day_14", "day_28", "day_56", "day_100")) %>%
# # 	drop_na() %>%
# # 	rename_at("day_3",~"mpa")
# # dat_7 <- dat %>%
# # 	select(-c("day_3", "day_14", "day_28", "day_56", "day_100")) %>%
# # 	drop_na() %>%
# # 	rename_at("day_7",~"mpa")
# # dat_14 <- dat %>%
# # 	select(-c("day_3", "day_7", "day_28", "day_56", "day_100")) %>%
# # 	drop_na() %>%
# # 	rename_at("day_14",~"mpa")
# # dat_28 <- dat %>%
# # 	select(-c("day_3", "day_7", "day_14", "day_56", "day_100")) %>%
# # 	drop_na() %>%
# # 	rename_at("day_28",~"mpa")
# # dat_56 <- dat %>%
# # 	select(-c("day_3", "day_7", "day_14", "day_28", "day_100")) %>%
# # 	drop_na() %>%
# # 	rename_at("day_56",~"mpa")
# # dat_100 <- dat %>%
# # 	select(-c("day_3", "day_7", "day_14", "day_28", "day_56")) %>%
# # 	drop_na() %>%
# # 	rename_at("day_100",~"mpa")
# 
# # Data preparation, creating one dat for each age
# names(dat) <- gsub(x = names(dat), pattern = "/", replacement = ".")
# dat_3 <- dat %>% filter(day == 3)
# dat_7 <- dat %>% filter(day == 7)
# dat_14 <- dat %>% filter(day == 14)
# dat_28 <- dat %>% filter(day == 28)
# dat_56 <- dat %>% filter(day == 56)
# dat_100 <- dat %>% filter(day == 100)
# 
# # Removing near zero variance columns
# nzv_3 <- nearZeroVar(dat_3)
# nzv_7 <- nearZeroVar(dat_7)
# nzv_14 <- nearZeroVar(dat_14)
# nzv_28 <- nearZeroVar(dat_28)
# nzv_56 <- nearZeroVar(dat_56)
# nzv_100 <- nearZeroVar(dat_100)
# dat_3 <- dat_3[,-nzv_3]
# dat_7 <- dat_7[,-nzv_7]
# dat_14 <- dat_14[,-nzv_14]
# dat_28 <- dat_28[,-nzv_28]
# dat_56 <- dat_56[,-nzv_56]
# dat_100 <- dat_100[,-nzv_100]
# 
# 
# # High correlation variables verification
# descr_cor_3 <- cor(select(dat_3, -c(mpa, id)))
# descr_cor_7 <- cor(select(dat_7, -c(mpa, id)))
# descr_cor_14 <- cor(select(dat_14, -c(mpa, id)))
# descr_cor_28 <- cor(select(dat_28, -c(mpa, id)))
# descr_cor_56 <- cor(select(dat_56, -c(mpa, id)))
# descr_cor_100 <- cor(select(dat_100, -c(mpa, id)))
# high_cor_3 <- sum(abs(descr_cor_3[upper.tri(descr_cor_3)]) > .999)
# high_cor_7 <- sum(abs(descr_cor_7[upper.tri(descr_cor_7)]) > .999)
# high_cor_14 <- sum(abs(descr_cor_14[upper.tri(descr_cor_14)]) > .999)
# high_cor_28 <- sum(abs(descr_cor_28[upper.tri(descr_cor_28)]) > .999)
# high_cor_56 <- sum(abs(descr_cor_56[upper.tri(descr_cor_56)]) > .999)
# high_cor_100 <- sum(abs(descr_cor_100[upper.tri(descr_cor_100)]) > .999)
# 
# 
# # Test and train data split
# reg <- list(
# 	dat_3 %>% select(-c(mpa, id)) %>% mutate(y = dat_3$mpa),
# 	dat_7 %>% select(-c(mpa, id)) %>% mutate(y = dat_7$mpa),
# 	dat_14 %>% select(-c(mpa, id)) %>% mutate(y = dat_14$mpa),
# 	dat_28 %>% select(-c(mpa, id)) %>% mutate(y = dat_28$mpa),
# 	dat_56 %>% select(-c(mpa, id)) %>% mutate(y = dat_56$mpa),
# 	dat_100 %>% select(-c(mpa, id)) %>% mutate(y = dat_100$mpa)
# )
# reg_seed <- c(
# 	1111, # 3
# 	1, # 7
# 	22, # 14
# 	11111, # 28
# 	111, # 56
# 	11 # 100
# )
# split_reg <- function(n){
# 	set.seed(reg_seed[[n]], sample.kind="Rounding")
# 	createDataPartition(reg[[n]]$y, p = .8, list = F)
# }
# trainIndex_reg <- lapply(list(1,2,3,4,5,6), split_reg)
# gen_dat <- function(n){
# 	regIndex <- trainIndex_reg[[n]]
# 	list(train = reg[[n]][regIndex,], test = reg[[n]][-regIndex,])
# }
# dats_reg <- lapply(list(1,2,3,4,5,6), gen_dat)
# names(dats_reg) <- c("d3", "d7", "d14", "d28", "d56", "d100")
# 
# 
# # Features selection based on models for each configuration
# # data1 <- dats_reg$d28$train # full
# # data2 <- dats_reg$d28$train[c(1:13, 21)] # no dummy vars
# # data3 <- dats_reg$d28$train[c(1:7, 21)] # only original variables
# # data4 <- dats_reg$d28$train[c(8:21)] # only new variables
# # data5 <- dats_reg$d28$train[c(8:13, 21)] # only new varibels, no dummy vars
# # test1 <- dats_reg$d28$test # full
# # test2 <- dats_reg$d28$test[c(1:13, 21)] # no dummy vars
# # test3 <- dats_reg$d28$test[c(1:7, 21)] # only original variables
# # test4 <- dats_reg$d28$test[c(8:21)] # only new variables
# # test5 <- dats_reg$d28$test[c(8:13, 21)] # only new varibels, no dummy vars
# # # parRF
# # modelLookup("parRF")
# # control_parRF <- trainControl(method='repeatedcv',number=10,repeats=5,search='grid')
# # fit_parRF<- function(data, n) {
# # 	set.seed(1, sample.kind = "Rounding")
# # 	tunegrid_parRF<- expand.grid(mtry = seq(1, length(data), n))
# # 	train(y ~ .,
# # 							data = data,
# # 							preProcess = c("center","scale"),
# # 							method='parRF',
# # 							tuneGrid=tunegrid_parRF,
# # 							trControl=control_parRF)
# # }
# # fit_parRF1 <- fit_parRF(data1, 3)
# # ggplot(fit_parRF1)
# # min(fit_parRF1$results$RMSE) # 6.26108
# # p1_parRF1 <- predict(fit_parRF1, newdata = test1)
# # RMSE(p1_parRF1, test1$y) # 4.887264
# # fit_parRF2 <- fit_parRF(data2, 1)
# # ggplot(fit_parRF2)
# # min(fit_parRF2$results$RMSE) # 6.268789
# # p_parRF2 <- predict(fit_parRF2, newdata = test2)
# # RMSE(p_parRF2, test2$y) # 4.812994
# # fit_parRF3 <- fit_parRF(data3, 1)
# # ggplot(fit_parRF3)
# # min(fit_parRF3$results$RMSE) # 6.361905
# # p_parRF3 <- predict(fit_parRF3, newdata = test3)
# # RMSE(p_parRF3, test3$y) # 5.083467
# # fit_parRF4 <- fit_parRF(data4, 1)
# # ggplot(fit_parRF4)
# # min(fit_parRF4$results$RMSE) # 8.705984
# # p_parRF4 <- predict(fit_parRF4, newdata = test4)
# # RMSE(p_parRF4, test4$y) # 8.083962
# # fit_parRF5 <- fit_parRF(data5, 1)
# # ggplot(fit_parRF5)
# # min(fit_parRF5$results$RMSE) # 8.691755
# # p_parRF5 <- predict(fit_parRF5, newdata = test5)
# # RMSE(p_parRF5, test5$y) # 7.991537
# 
# 
# # Regression models
# data3 <- dats_reg$d3$train
# data7 <- dats_reg$d7$train
# data14 <- dats_reg$d14$train
# data28 <- dats_reg$d28$train
# data56 <- dats_reg$d56$train
# data100 <- dats_reg$d100$train
# test3 <- dats_reg$d3$test
# test7 <- dats_reg$d7$test
# test14 <- dats_reg$d14$test
# test28 <- dats_reg$d28$test
# test56 <- dats_reg$d56$test
# test100 <- dats_reg$d100$test
# get_trControl <- function(n, r){
# 	trainControl(method='repeatedcv',number=n,repeats=r,search='grid')
# }
# trControl3 <- get_trControl(30, 10)
# trControl7 <- get_trControl(10, 10)
# trControl14 <- get_trControl(30, 10)
# trControl28 <- get_trControl(30, 10)
# trControl56 <- get_trControl(30, 10)
# trControl100 <- get_trControl(10, 10)
# get_tuneGrid <- function(data){
# 	expand.grid(mtry = seq(1, length(data), 1))
# }
# tuneGrid3 <- get_tuneGrid(data3)
# tuneGrid7 <- get_tuneGrid(data7)
# tuneGrid14 <- get_tuneGrid(data14)
# tuneGrid28 <- get_tuneGrid(data28)
# tuneGrid56 <- get_tuneGrid(data56)
# tuneGrid100 <- get_tuneGrid(data100)
# set.seed(1, sample.kind = "Rounding")
# fit_3 <- train(y ~ .,
# 															data = data3,
# 															preProcess = c("center","scale"),
# 															method='parRF',
# 															tuneGrid=tuneGrid3,
# 															trControl=trControl3)
# p_3 <- predict(fit_3, newdata = test3)
# RMSE_test_3 <- RMSE(p_3, test3$y)
# RMSE_test_3 # 3.31037
# fit_3$bestTune # mtry = 6
# 
# # 
# # set.seed(1, sample.kind = "Rounding")
# # fit_7 <- train(y ~ .,
# # 															data = data7,
# # 															preProcess = c("center","scale"),
# # 															method='parRF',
# # 															tuneGrid=tuneGrid7,
# # 															trControl=trControl7)
# # p_7 <- predict(fit_7, newdata = test7)
# # RMSE_test_7 <- RMSE(p_7, test7$y)
# # RMSE_test_7 # 4.361987
# # fit_7$bestTune # mtry = 2
# # set.seed(1, sample.kind = "Rounding")
# # fit_14 <- train(y ~ .,
# # 																data = data14,
# # 																preProcess = c("center","scale"),
# # 																method='parRF',
# # 																tuneGrid=tuneGrid14,
# # 																trControl=trControl14)
# # p_14 <- predict(fit_14, newdata = test14)
# # RMSE_test_14 <- RMSE(p_14, test14$y)
# # RMSE_test_14 # 4.620515
# # fit_14$bestTune # mtry = 13
# # set.seed(1, sample.kind = "Rounding")
# # fit_28 <- train(y ~ .,
# # 																data = data28,
# # 																preProcess = c("center","scale"),
# # 																method='parRF',
# # 																tuneGrid=tuneGrid28,
# # 																trControl=trControl28)
# # p_28 <- predict(fit_28, newdata = test28)
# # RMSE_test_28 <- RMSE(p_28, test28$y)
# # RMSE_test_28 # 4.716698
# # fit_28$bestTune # mtry = 11
# # set.seed(1, sample.kind = "Rounding")
# # fit_56 <- train(y ~ .,
# # 																data = data56,
# # 																preProcess = c("center","scale"),
# # 																method='parRF',
# # 																tuneGrid=tuneGrid56,
# # 																trControl=trControl56)
# # p_56 <- predict(fit_56, newdata = test56)
# # RMSE_test_56 <- RMSE(p_56, test56$y)
# # RMSE_test_56 # 5.939163
# # fit_56$bestTune # mtry = 8
# # set.seed(1, sample.kind = "Rounding")
# # fit_100 <- train(y ~ .,
# # 																	data = data100,
# # 																	preProcess = c("center","scale"),
# # 																	method='parRF',
# # 																	tuneGrid=tuneGrid100,
# # 																	trControl=trControl100)
# # p_100 <- predict(fit_100, newdata = test100)
# # RMSE_test_100 <- RMSE(p_100, test100$y)
# # RMSE_test_100 # 5.851088
# # fit_100$bestTune # mtry = 8
# 
# 
# 
# # # Results
# # The test *RMSE* for each model in ascending order of age was `r round(RMSE_test_3,2)`, `r round(RMSE_test_7,2)`, `r round(RMSE_test_14,2)`, `r round(RMSE_test_28,2)`, `r round(RMSE_test_56,2)` and `r round(RMSE_test_100,2)` respectively. The table \ref{tab:table-reg-models} presents the details and results of each model (\ref{show-table-reg-models}). The figure \ref{fig:results-comparison} compares the actual and predicted values (\ref{show-results-comparison}), and the following tables show the best and worst results for each model (\ref{show-table-10}).
# # ```{r table-reg-models, echo=F}
# # # Table - Models details
# # colNames <- c("Model", "mtry", "CV", "Repetitions",
# # 														"RMSE (train)", "RMSE (test)")
# # caption <- "Regression models results"
# # day <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
# # dat_reg_models <- data.frame(
# # 	dia = day,
# # 	mtry = c(fit_3$bestTune$mtry, fit_7$bestTune$mtry, fit_14$bestTune$mtry,
# # 										fit_28$bestTune$mtry, fit_56$bestTune$mtry, fit_100$bestTune$mtry),
# # 	number = c(trControl3$number, trControl7$number, trControl14$number,
# # 												trControl28$number,trControl56$number,trControl100$number),
# # 	repeats = c(trControl3$repeats, trControl7$repeats, trControl14$repeats,
# # 													trControl28$repeats,trControl56$repeats,trControl100$repeats),
# # 	RMSE_train = c(min(fit_3$results$RMSE), min(fit_7$results$RMSE),
# # 																min(fit_14$results$RMSE), min(fit_28$results$RMSE),
# # 																min(fit_56$results$RMSE), min(fit_100$results$RMSE)),
# # 	RMSE_test = c(RMSE_test_3, RMSE_test_7, RMSE_test_14,
# # 															RMSE_test_28, RMSE_test_56, RMSE_test_100)
# # )
# # kable(
# # 	dat_reg_models,
# # 	col.names = colNames,
# # 	escape = F,
# # 	booktabs = T,
# # 	caption = caption,
# # 	linesep = "\\addlinespace",
# # 	align = "c"
# # )  %>%
# # 	kable_styling(latex_options = c("HOLD_position"))
# # ```
# # ```{r results-comparison, echo=F, message=F, warning=F, fig.height=4, fig.cap=cap}
# # # Figure - Models comparison
# # cap <- "Actual vs Predicted values in each model"
# # models <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
# # xlabel <- "Actual (MPa)"
# # ylabel <- "Predicted (MPa)"
# # preds <- list(p_3, p_7, p_14, p_28, p_56, p_100)
# # actuals <- list(test3$y, test7$y, test14$y, test28$y, test56$y, test100$y)
# # gen_res_df <- function(ind){
# # 	data.frame(actual = actuals[[ind]], pred = preds[[ind]], model = models[[ind]])
# # }
# # res_df <- lapply(1:6, gen_res_df)
# # res_df <- bind_rows(res_df)
# # res_df$model <- factor(res_df$model,levels=models)
# # res_df %>%
# # 	ggplot(aes(actual, pred)) +
# # 	facet_wrap(~ model, ncol=3) +
# # 	geom_point(alpha=0.5) +
# # 	theme_bw() +
# # 	geom_abline(slope=1, intercept=0) +
# # 	xlab(xlabel) +
# # 	ylab(ylabel)
# # ```
# # ```{r table-10, echo=F}
# # # Results tables of 10 best and worst results
# # colNames1 = c("Actual", "Predicted", "Error", "","Actual", "Predicted", "Error")
# # colNames2 = c("Best 10"=3,"", "Worst 10"=3)
# # caption_0 <- "Model of "
# # get_X <- function(pred, actual, X=10){
# # 	diff <- abs(pred - actual)
# # 	diff_2 <- pred - actual
# # 	ind_min <- which(diff <= max(sort(diff, decreasing = F)[1:X]), arr.ind = T)
# # 	ind_max <- which(diff >= min(sort(diff, decreasing = T)[1:X]), arr.ind = T)
# # 	df_min <- data.frame(
# # 		actual_min=actual[ind_min],
# # 		pred_min=pred[ind_min],
# # 		diff_min=diff[ind_min],
# # 		diff_min_2=diff_2[ind_min]
# # 	)
# # 	df_max <- data.frame(
# # 		actual_max=actual[ind_max],
# # 		pred_max=pred[ind_max],
# # 		diff_max=diff[ind_max],
# # 		diff_max_2=diff_2[ind_max]
# # 	)
# # 	df_max <- df_max[order(-df_max$diff_max),]
# # 	df_min <- df_min[order(df_min$diff_min),]
# # 	df_null <- data.frame(null_col = rep(c(""), X))
# # 	res <- cbind(df_min,df_null, df_max)
# # 	res <- res %>% select(-c(diff_max, diff_min))
# # 	rownames(res) <- c()
# # 	res
# # }
# # gen_kable <- function(ind){
# # 	df <- get_X(preds[[ind]], actuals[[ind]])
# # 	caption <- paste0(caption_0,models[ind])
# # 	kable(
# # 		df,
# # 		col.names = colNames1,
# # 		escape = F,
# # 		booktabs = T,
# # 		caption = caption,
# # 		linesep = "\\addlinespace",
# # 		align = "c"
# # 	)  %>%
# # 		column_spec(4, width = "1cm",) %>%
# # 		add_header_above(header = colNames2, line = T, align = "c") %>%
# # 		kable_styling(latex_options = c("HOLD_position"))
# # }
# # gen_kable(1)
# # gen_kable(2)
# # gen_kable(3)
# # gen_kable(4)
# # gen_kable(5)
# # gen_kable(6)
# # ```
# # 
# # 
# # 
# # # Discussion
# # The models built present satisfactory results and prove that the compressive strength of concrete can be predicted relatively easily. The alternative adopted to create a model for each set of age proved to be a valid method, managing to stratify to obtain specific results for each set. The studies cited in the introduction using the same dataset have similar results, as expected. The \ref{tab:works-comparison} table presents the results of these works (\ref{show-works-comparison}), and the table \ref{tab:results} presents the values found for easy comparison (\ref{show-results}) .
# # ```{r works-comparison, echo=F}
# # # Table - Comparison of other works
# # colNames = c("Author","Year" ,"Algorithm", "RMSE")
# # caption <- "Comparison of other works"
# # works <- data.frame(
# # 	autor = c("Pierobon", "Hameed", "Raj","Modukuru" ,"Alshamiri", "Abban"),
# # 	ano = c("2018", "2020", "2018","2020" ,"2020", "2016"),
# # 	modelo = c("Ensemble com 5 algorítimos", "Artificial Neural Networks",
# # 												"Gradient Boosting Regressor","Random Forest Regressor" ,
# # 												"Regularized Extreme Learning Machine",
# # 												"Support Vector Machines with Radial Basis Function Kernel"),
# # 	RMSE = c("4.150", "4.736", "4.957","5.080","5.508", "6.105")
# # )
# # kable(
# # 	works,
# # 	col.names = colNames,
# # 	escape = F,
# # 	booktabs = T,
# # 	caption = caption,
# # 	linesep = "\\addlinespace",
# # 	align = "l"
# # )  %>%
# # 	kable_styling(latex_options = c("HOLD_position"))
# # ```
# # ```{r results, echo=F}
# # # Table - Final results
# # colNames <- c("Model", "RMSE")
# # caption <- "Final result"
# # day <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
# # dat_reg_models <- data.frame(
# # 	dia = day,
# # 	RMSE_test = c(RMSE_test_3, RMSE_test_7, RMSE_test_14,
# # 															RMSE_test_28, RMSE_test_56, RMSE_test_100)
# # )
# # kable(
# # 	dat_reg_models,
# # 	col.names = colNames,
# # 	escape = F,
# # 	booktabs = T,
# # 	caption = caption,
# # 	linesep = "\\addlinespace",
# # 	align = "c"
# # )  %>%
# # 	kable_styling(latex_options = c("HOLD_position"))
# # ```
# # Following the line of reasoning of this work, it can be performed with different algorithms, the results found here used only one (*Parallel Random Forest*), even though it was theoretically the "best" found, other algorithms can present even better results. Another option is to create an *ensemble* of various algorithms, just like @Pierobon2018, but with the separation of age sets proposed here. In addition, it can be performed with a larger dataset, ideally with the same number of samples in each age set, a more homogeneous distribution of compressive strength, and less variance between samples.
# # 
# # 
# # 
# # 
# # 
