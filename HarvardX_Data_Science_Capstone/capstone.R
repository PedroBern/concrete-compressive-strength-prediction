
# Install libraries, if not already installed
if(!require(tidyverse)) install.packages("tidyverse")
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(caret)) install.packages("caret")
if(!require(knitr)) install.packages("knitr")
if(!require(kableExtra)) install.packages("kableExtra")
if(!require(gdata)) install.packages("gdata")
if(!require(dplyr)) install.packages("dplyr")
if(!require(tidyr)) install.packages("tidyr")
if(!require(cowplot)) install.packages("cowplot")
if(!require(pastecs)) install.packages("pastecs")
if(!require(factoextra)) install.packages("factoextra")
if(!require(reshape2)) install.packages("reshape2")
if(!require(purrr)) install.packages("purrr")
if(!require(gridExtra)) install.packages("gridExtra")
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
		
		
# Defining column names and units
colNames <- c("ID", "Cement", "B.F.S.", "Fly ash", "Water",
														"Superp.", "C.Aggregate", "F.Aggregate", "Day", "Comp.Str.")
dfUnits <- c("", "$kg/m^3$", "$kg/m^3$","$kg/m^3$","$kg/m^3$",
													"$kg/m^3$","$kg/m^3$","$kg/m^3$","","$MPa$")

		

# Table - First samples
caption <- "First 6 samples"
kable(
	dat[1:6,],
	col.names = dfUnits,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c"
) %>%
	add_header_above(header = colNames, line = F, align = "c") %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down"))

		
# Removing duplicated samples
n_distinct_samples <- dat %>% select(-c(id)) %>% n_distinct()
n_duplicated_samples <- n_inicial_samples - n_distinct_samples
dat <- dat[!duplicated(select(dat, -c(id))),]
n_samples <- nrow(dat)
		

# Table - Samples with same composition
same_samples <- dat %>%
	filter(id %in% c(653, 678, 654, 681))
caption <- "Samples with same composition"
kable(
	same_samples[order(same_samples$day),],
	col.names = dfUnits,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c",
	row.names = FALSE
) %>%
	add_header_above(header = colNames, line = F, align = "c") %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down"))


# Table - Same samples with different results
same_samples_2 <- dat %>%
	filter(id %in% c(472, 473, 474))
caption <- "Same samples with different results"
kable(
	same_samples_2[order(same_samples_2$day),],
	col.names = dfUnits,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c",
	row.names = FALSE
) %>%
	add_header_above(header = colNames, line = F, align = "c") %>%
	kable_styling(latex_options = c("scale_down"))


# Data cleaning
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
dat$id<-factor(dat$id)
n_samples <- nrow(dat)
n_distinct_samples <- n_distinct(dat$id)


# Table - Previous samples after processing
same_samples <- dat %>%
	filter(id == 653 | id == 472 & day == 28)
caption <- "Previous samples after processing"
kable(
	same_samples[order(same_samples$id, same_samples$day),],
	col.names = dfUnits,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c",
	row.names = FALSE,
	digits = 2
) %>%
	add_header_above(header = colNames, line = F, align = "c") %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down"))


# Figure - Compressive strength (MPa) vs age (days)
cap <- "Boxplot - Compressive strength (MPa) vs age (days)"
ylabel <- "Compressive strength (MPa)"
xlabel <- "Age (days)"
dat %>%
	ggplot(aes(x=factor(day), y=mpa)) +
	geom_boxplot() +
	geom_jitter(alpha=0.2)  +
	theme_bw() +
	ylab(ylabel) +
	xlab(xlabel)


# Figure - Principal component analysis - 90, 91 e 100 days
dat_90_91_100 <- dat %>%
	ungroup() %>%
	filter(day %in% c(90, 91, 100)) %>%
	select(-c(id, mpa))
cap <- "Principal component analysis - 90, 91 e 100 days"
colnames(dat_90_91_100) <- c(
	"Cem.", "B.F.S.", "Fly.A.","Water","Sup.","C.Ag.","F.Ag.","day")
pca <- prcomp(select(dat_90_91_100, -c(day)), scale = TRUE)
habillage <- dat_90_91_100$day
fviz_pca_biplot(
	pca,
	geom.ind = "point",
	habillage=habillage,
	addEllipses = TRUE,
	ellipse.level=0.75) +
	ggtitle("") +
	theme_bw() +
	coord_cartesian(xlim = c(-3, 3.5), ylim = c(3, -5))


# Figure - Compressive strength through time
cap <- "Compressive strength through time"
ylabel <- "MPa"
xlabel <- "Age (days)"
dat_duplicated_only <- dat %>%
	group_by(id) %>%
	filter(n()>5) %>%
	select(id, mpa, day)
dat_duplicated_only %>%
	ggplot(aes(day, mpa, fill=id, alpha = 0.5)) +
	geom_line() +
	xlab(xlabel) +
	ylab(ylabel) +
	theme_bw() +
	theme(legend.position = "none")


# Joining 90, 91 and 100 days data
ind_90 <- dat$id[which(dat$day == "90")]
ind_91 <- dat$id[which(dat$day == "91")]
ind_100 <- dat$id[which(dat$day == "100")]
sum_duplicated <- sum(duplicated(c(ind_90, ind_91, ind_100))) # 0
dat <- dat %>%
	ungroup() %>%
	mutate(day = ifelse(day %in% c(91, 90), 100, day))


# Figure - Ages frequency
cap <- "Ages frequency"
ylabel <- "Frequency"
xlabel <- "Age (days)"
dat %>%
	ggplot(aes(x = factor(day))) +
	geom_bar() +
	theme_bw() +
	xlab(xlabel) +
	ylab(ylabel)


# Removing ages with frequency lower than 50
dat <- dat[dat$day %in% c(3, 7, 14, 28, 56, 100),]


# Data reorganization
dat <- dat %>%
	group_by_at(vars(-mpa)) %>%
	mutate(row_id = 1:n()) %>% ungroup() %>%
	spread(day, mpa, sep = "_") %>%
	select(-row_id)


# Table - First 6 samples after reorganization
caption <- "First 6 samples after reorganization"
colNames2 = c("ID", "Cement", "B.F.S", "Fly ash", "Water",
														"Superp.", "Coarse Ag.", "Fine Ag.", "3 days", "7 days",
														"14 days", "28 days", "56 days", "100 days")
dfUnits2 <- c("", "$kg/m^3$", "$kg/m^3$","$kg/m^3$","$kg/m^3$",
														"$kg/m^3$", "$kg/m^3$","$kg/m^3$","$MPa$","$MPa$",
														"$MPa$","$MPa$","$MPa$","$MPa$")
kable(
	head(dat[order(dat$id),]),
	col.names = dfUnits2,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c"
) %>%
	add_header_above(header = colNames2, line = F, align = "c") %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down"))


# Total samples
n_samples <- nrow(dat) # 416
n_distinct_samples <- n_distinct(dat$id) # 416


# Adding New features
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


# Table - New features
caption <- "New features"
colNames7 = c("ID", "Class","Approximated Mix",
														"Water / Cement", "Fine Ag. / Cement",
														"Coarse Ag. / Cement", "Fine Ag. / Coarse Ag.",
														"Water / Coarse Ag.", "Water / Fine Ag.")
kable(
	head(dat[order(dat$id),][,c(1,15:22)]),
	col.names = colNames7,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c",
	digits = 4
) %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down")) %>%
	column_spec(2, width = "1.5cm") %>%
	column_spec(3, width = "2cm") %>%
	column_spec(4:9, width = "1.7cm")


# Table - Descriptive statistics - continuous variables
summ <- t(
	stat.desc(select(dat, -c(id, class, mix_app))))
caption <- "Descriptive statistics - continuous variables"
colnames(summ) <- c("Samples", "Null", "NA", "Min", "Max", "Range",
																				"Sum", "Median", "Mean", "SE mean",
																				"CI mean","Variance", "Std.Dev.", "Coef.Var")
rownames(summ) = c("Cement", "B.F.S.", "Fly ash", "Water",
																			"Superplast.", "Coarse agg.", "Fine agg.", "3 days", "7 days",
																			"14 days", "28 days", "56 days", "100 days",
																			"Water / Cement", "Fine agg. / Cement",
																			"Coarse agg. / Cement", "Fine agg. / Coarse agg.",
																			"Water / Coarse agg.", "Water / Fine agg.")
kable(
	summ,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c",
	digits = c(0,0,0,2,2,2,2,2,2,2,2,2,2,2)
) %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down")) %>%
	column_spec(c(1,10:15), width = "1.5cm")


# Figure - Descriptive statistics - categorical variables
cap <- "Descriptive statistics - categorical variables"
name1 <- "Percentage"
name2 <- "Accumulated percentage"
ylabel <- "Frequency"
xlabel1 <- "Class"
xlabel2 <- "Approximate Mix"
format_percent = function(n){
	paste(n, "%", sep = "")
}
format_class <- function(cls){
	str_remove_all(cls, "C")
}
f_class <- freq(dat$class, cum = TRUE, sort = "dec", total = F) %>%
	select(n, "%", "%cum") %>%
	mutate(class = row.names(.)) %>%
	mutate(class_n = as.numeric(format_class(class)))
f_cls_labels = function(n) {
	f_class$class[n]
}
f_cls_acc_labels = function(n){
	paste(f_class$`%cum`[n], "%", sep = "")
}
p1 <- f_class %>%
	ggplot(aes(x = as.integer(reorder(class_n, -n)), y = n)) +
	geom_bar(stat = 'identity') +
	scale_y_continuous(
		sec.axis = sec_axis(~./length(dat$class) * 100,
																						name = name1,
																						labels = format_percent)) +
	scale_x_continuous(labels = f_cls_labels, breaks = 1:16, limits = c(0.5,16.5),
																				sec.axis = sec_axis(~., breaks = 1:16,
																																								name = name2,
																																								labels = f_cls_acc_labels)) +
	theme_bw() +
	theme(panel.grid.minor.y = element_blank()) +
	xlab(xlabel1) +
	ylab(ylabel) +
	coord_flip()
format_mix <- function(mix){
	str_remove_all(mix, ":")
}
f_mix <- freq(dat$mix_app, cum = TRUE, sort = "dec", total = F) %>%
	select(n, "%", "%cum") %>%
	mutate(mix = row.names(.)) %>%
	mutate(mix_n = as.numeric(format_mix(mix)))
f_mix_labels = function(n) {
	f_mix$mix[n]
}
f_mix_acc_labels = function(n){
	paste(f_mix$`%cum`[n], "%", sep = "")
}
p2 <- f_mix %>%
	ggplot(aes(x = as.integer(reorder(mix_n, -n)), y = n)) +
	geom_bar(stat = 'identity') +
	scale_y_continuous(
		sec.axis = sec_axis(~./length(dat$mix_app) * 100,
																						name = name1,
																						labels = format_percent)) +
	scale_x_continuous(labels = f_mix_labels, breaks = 1:24, limits = c(0.5,24.5),
																				sec.axis = sec_axis(~., breaks = 1:24,
																																								name = name2,
																																								labels = f_mix_acc_labels)) +
	theme_bw() +
	theme(panel.grid.minor.y = element_blank()) +
	xlab(xlabel2) +
	ylab(ylabel) +
	coord_flip()
grid.arrange(p1, p2, ncol=2)


# Figure - Correlation grouped by age
cor_dat <- dat %>% select(-c(id))
cap <- "Correlations at each age"
f_lvl <- c("3 days", "7 days", "14 days","28 days", "56 days", "100 days")
name <- "Correlation"
colnames_dat <- c("Cement", "B.F.S.", "Fly ash", "Water",
																		"Superplast.", "Coarse agg.", "Fine agg.",
																		"3", "7", "14", "28", "56", "100",
																		"class", "mix_app", "W./C.", "F.A./C.",
																		"C.A./C.", "F.A./C.A.",
																		"W./C.A.", "W./F.A.")
colnames(cor_dat) <- colnames_dat
cor_dat <- cor_dat %>%
	gather("day", "mpa", c("3", "7", "14", "28", "56", "100")) %>%
	drop_na()
cor_day <- function(d){
	res <- cor_dat %>%
		filter(day == d) %>%
		select(-c(day, class, mix_app)) %>%
		cor(.)
	res[upper.tri(res)] <- NA
	return(res)
}
cor_dats <- list(cor_day(3), cor_day(7), cor_day(14),
																	cor_day(28), cor_day(56), cor_day(100))
melt_day <- function(df, d){
	df %>%
		melt() %>%
		mutate(day = d)
}
melt_dats <- list(melt_day(cor_dats[1], 3), melt_day(cor_dats[2], 7),
																		melt_day(cor_dats[3], 14), melt_day(cor_dats[4],28),
																		melt_day(cor_dats[5], 56), melt_day(cor_dats[6],100))
melt_dat_final <- melt_dats %>%
	reduce(rbind) %>%
	filter(value != 1)
melt_dat_final$day <- factor(melt_dat_final$day)
levels(melt_dat_final$day) <- f_lvl
melt_dat_final %>%
	ggplot(aes(x=reorder(Var1, desc(Var1)), y=Var2, fill=value)) +
	geom_tile(color = "white") +
	facet_wrap(~day, ncol=3) +
	scale_fill_gradient2(low = "red", high = "blue", mid = "white",
																						midpoint = 0, limit = c(-1,1),name=name, na.value="white") +
	xlab("") +
	ylab("") +
	theme_minimal() +
	theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
	theme(panel.border = element_blank(), panel.grid.major = element_blank(),
							panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black"))


# Figure - Correlation over time
cap <- "Correlation of variables with compressive strength over time"
name <- "Correlation"
melt_dat_final %>%
	filter(Var1 == "mpa" | Var2 == "mpa") %>%
	ggplot(aes(x=reorder(Var1, desc(Var1)), y=Var2, fill=value)) +
	geom_tile(color = "white") +
	facet_wrap(~day, ncol=6) +
	scale_fill_gradient2(low = "red", high = "blue", mid = "white",
																						midpoint = 0, limit = c(-1,1),name=name, na.value="white") +
	xlab("") +
	ylab("") +
	geom_text(aes(label = round(value, 2)), size = 2.5) +
	theme_minimal() +
	theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
	theme(panel.border = element_blank(), panel.grid.major = element_blank(),
							panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black"))


# Figure - Relationship between approximated mix, water, MPa and age
cap <- "Relationship between approximated mix, water, MPa and age"
d <- " days"
xlabel <- "Approximated mix"
ylabel <- "Compressive strength (MPa)"
label <- "Water /\nCement"
mix_dat <- dat %>%
	select(c(day_3,day_7,day_14,day_28,day_56,day_100,
										mix_app, `water_/_cement`,
										`fine_aggregate_/_cement`,
										`coarse_aggregate_/_cement`))

labs <- paste(c("3","7","14","28","56","100"), d, sep="")
mix_dat <- mix_dat %>%
	gather("day", "mpa", -c(mix_app, `water_/_cement`,
																									`fine_aggregate_/_cement`,
																									`coarse_aggregate_/_cement`)) %>%
	drop_na()
lvls <- paste("day_",c("3","7","14","28","56","100"), sep="")
mix_dat$day <- factor(mix_dat$day, levels=lvls)
levels(mix_dat$day) <- labs
min_x <- min(mix_dat$`water_/_cement`)
max_x <- max(mix_dat$`water_/_cement`)
s_x <- max_x - min_x
mix_dat %>%
	ggplot(aes(x=mix_app, y=mpa, colour = `water_/_cement`)) +
	geom_point()  +
	facet_wrap(~ day, ncol=2) +
	theme_bw() +
	ylab(ylabel) +
	xlab(xlabel) +
	scale_shape_manual(values=c(16, 2, 8)) +
	scale_colour_gradient2(low = "red", mid = "yellow", high = "blue",
																								midpoint = s_x / 2 + min_x ,limits = c(min_x, max_x),
																								breaks = c(round(min_x, 2),
																																			round(s_x*0.25 + min_x,2),
																																			round(s_x*0.5 + min_x,2),
																																			round(s_x * 0.75 + min_x,2),
																																			round(max_x, 2))) +
	labs(colour = label) +
	theme_minimal() +
	theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
	theme(panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black"))


# Figure - Relationship between concrete main features
cap <- "Relationship between concrete main features"
d <- " days"
xlabel <- "Water / Cement"
ylabel <- "Compressive strength (MPa)"
colour <- "Fine Agg. /\nCement"
size <- "Coarse Agg. /\nCement"
min_x_2 <- min(mix_dat$`fine_aggregate_/_cement`)
max_x_2 <- max(mix_dat$`fine_aggregate_/_cement`)
s_x_2 <- max_x_2 - min_x_2
mix_dat %>%
	ggplot(aes(x=`water_/_cement`, y=mpa,
												colour = `fine_aggregate_/_cement`,
												size = `coarse_aggregate_/_cement`)) +
	geom_point(alpha = 0.5)  +
	facet_wrap(~ day, ncol=2) +
	theme_bw() +
	ylab(ylabel) +
	xlab(xlabel) +
	scale_colour_gradient2(low = "red", mid = "yellow", high = "blue",
																								midpoint = (s_x_2 / 2) + min_x_2,
																								limits = c(min_x_2, max_x_2),
																								breaks = c(round(min_x_2, 2),
																																			round(s_x_2*0.25 + min_x_2,2),
																																			round(s_x_2*0.5 + min_x_2,2),
																																			round(s_x_2 * 0.75 + min_x_2,2),
																																			round(max_x_2 - 0.01, 2))
	) +
	labs(colour = colour, size = size) +
	ylim(c(-5,85)) +
	scale_radius() +
	theme_minimal() +
	theme(panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black"))


# Figure - Variables distribution
cap <- "Variables distribution"
colnames_dat <- c("Cement", "B.F.S.", "Fly ash", "Water",
																		"Superplast.", "Coarse agg.", "Fine agg.",
																		"Water / Cement", "Fine agg. / Cement",
																		"Coarse agg. / Cement", "Fine agg. / Coarse agg.",
																		"Water / Coarse agg.", "Water / Fine agg.")
dist_dat <- dat %>%
	select(-c(id, class, day_3, day_7, day_14, day_56, day_100, mix_app))

colnames(dist_dat) <- colnames_dat
dist_dat <- dist_dat %>%
	gather("Var", "value") %>%
	mutate(value = as.numeric(value))
dist_dat %>%
	ggplot(aes(value)) +
	geom_histogram(aes(y = ..density..),
																colour = "black",
																fill = "white") +
	geom_density(alpha = .5, fill = "lightseagreen") +
	facet_wrap(~ Var, ncol=3, scale = "free") +
	theme_minimal() +
	xlab("") +
	ylab("") +
	theme(panel.border = element_blank(), panel.grid.major = element_blank(),
							panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black"))


# Figure - Variables distribution grouped by age
days_labs <- c("3","7","14","28","56","100")
cap <- "Variables distribution grouped by age"
colnames_dat <- c("Cement", "B.F.S.", "Fly ash", "Water",
																		"Superplast.", "Coarse agg.", "Fine agg.",
																		days_labs,
																		"Water / Cement", "Fine agg. / Cement",
																		"Coarse agg. / Cement", "Fine agg. / Coarse agg.",
																		"Water / Coarse agg.", "Water / Fine agg.")
dist_dat_2 <- dat %>%
	select(-c(id, class, mix_app))
colnames(dist_dat_2) <- colnames_dat
dist_dat_2 <- dist_dat_2 %>%
	gather("day", "mpa", days_labs) %>%
	drop_na() %>%
	gather("Var", "value", -c("day")) %>%
	mutate(day = factor(day, levels = days_labs))
dist_dat_2 %>%
	ggplot(aes(x = day, y = value)) +
	geom_violin(color = NA,
													fill = "lightseagreen",
													alpha = .5,
													na.rm = TRUE,
													scale = "count") +
	geom_boxplot(alpha = 0.2) +
	facet_wrap(~ Var, ncol=3, scale = "free") +
	theme_minimal() +
	theme(panel.border = element_blank(), panel.grid.major = element_blank(),
							panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black")) +
	xlab("") +
	ylab("")


# Figure - Principal component analysis on ingredients
cap <- "Principal component analysis on ingredients"
colnames_dat <- c(
	"Cem.", "B.F.S.", "F.A.", "Wat.", "Sup.", "C.Agg.",
	"F.Agg.","WxC", "F.Agg.xC","C.Agg.xC","F.Agg.xC",
	"WxC.Agg.","WxF.Agg."
)
class_list <- list(low="0", normal="20", medium="40", high="70")
dat_pca <- dat %>%
	select(-c(id, class, mix_app,
											"day_3", "day_7", "day_14", "day_28", "day_56", "day_100"))
colnames(dat_pca) <- colnames_dat
class_2 <- dat$day_28
class_2[class_2 < 20] = "0"
class_2[class_2 >= 20 & class_2 < 40] = "20"
class_2[class_2 >= 40 & class_2 < 70] = "40"
class_2[class_2 >= 70] = "70"
class_2 <- factor(class_2)
levels(class_2) <- class_list
pca <- prcomp(dat_pca, scale = TRUE)
fviz_pca_ind(
	pca,
	geom.ind = "point",
	habillage=class_2,
	addEllipses = T,
	ellipse.level=0.95) +
	ggtitle("") +
	theme_bw()


# Dummy variables
dummies <- dummyVars( ~ mix_app, data = dat)
dummyDat <- data.frame(predict(dummies, newdata = dat))
dummyDat$id <- dat$id
dat <- dat %>%
	select(-c(mix_app)) %>%
	full_join(., dummyDat)


# Data preparation
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


# Table - First 18 columns of the 6 first samples of 28 days
colNames = c("ID", "Cement", "B.F.S.", "Fly ash", "water",
													"Superp.", "Coarse Agg.", "Fine Agg.", "MPa", "Class",
													"Wat./", "F.Agg./", "C.Agg./",
													"F.Agg./","Wat./", "Wat./", "App Mix" = 2)
dfUnits <- c("", "$kg/m^3$", "$kg/m^3$","$kg/m^3$","$kg/m^3$",
													"$kg/m^3$", "$kg/m^3$","$kg/m^3$","$MPa$","", "Ci.",
													"Ce.", "Ce.", "C.Agg.", "C.Agg.", "F.Agg.", "1:1:2", "1:2:2")
caption <- "First 18 columns of the 6 first samples of 28 days"
dat_table <- dat_28[1:18]
kable(
	head(dat_table[order(dat_table$id),]),
	col.names = dfUnits,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	digits = 2,
	align = "c"
) %>%
	add_header_above(header = colNames, line = F, align = "c") %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down"))


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


# Distribution of test and train data
cap <- "Distribution of test and train data"
d_lab <- " days"
ylabel <- "Density"
g1 <- "Train"
g2 <- "Test"
dens <- function(d, n){
	dens <- full_join(
		d$train %>%
			select(y) %>%
			mutate(Group = g1, day = str_sub(n, 2)),
		d$test %>%
			select(y) %>%
			mutate(Group = g2, day = str_sub(n, 2))
	)
	dens
}
densities <- imap(dats_reg, dens) %>%
	reduce(rbind) %>%
	mutate(day_f = factor(day, levels=c('3','7','14','28', '56', '100')))
labs <- paste(c("3","7","14","28","56","100"), d_lab, sep="")
levels(densities$day_f) <- labs
densities %>%
	ggplot(aes(y, fill = Group)) +
	geom_density(alpha = 0.5) +
	facet_wrap(~day_f, ncol=3) +
	xlab("MPa") +
	ylab(ylabel) +
	theme_bw() +
	theme_minimal() +
	theme(panel.border = element_blank(), panel.grid.major = element_blank(),
							panel.grid.minor = element_blank(),
							axis.line = element_line(colour = "black"))


# Naive model
res <- function(d, n){
	data.frame(
		day = str_sub(n, 2),
		mean_mpa = mean(d$train$y)
	)
}
ing_model <- imap(dats_reg, res)
get_rmse <- function(d, n){
	data.frame(
		rmse_train = RMSE(d$train$y, ing_model[[n]]$mean_mpa),
		rmse_test =  RMSE(d$test$y, ing_model[[n]]$mean_mpa),
		day = str_sub(n, 2)
	)
}
rmses <- imap(dats_reg, get_rmse) %>%
	reduce(rbind)
ing_model_df <- ing_model %>% reduce(rbind)
df_performance_reg <- full_join(ing_model_df, rmses)


# Table - Naive models
colNames = c("Age", "Mean $MPa$ (train)", "RMSE (train)", "RMSE (test)")
caption <- "Naive models"
kable(
	df_performance_reg,
	col.names = colNames,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "c"
)  %>%
	kable_styling(latex_options = c("HOLD_position"))


# Features selection
# Run the models with no optimization with different features
# to select the combinations that should be used in the
# final models
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
fit_parRF1 <- fit_parRF(data1, 3)
ggplot(fit_parRF1)
min(fit_parRF1$results$RMSE) # 6.26108
p1_parRF1 <- predict(fit_parRF1, newdata = test1)
RMSE(p1_parRF1, test1$y) # 4.887264

fit_parRF2 <- fit_parRF(data2, 1)
ggplot(fit_parRF2)
min(fit_parRF2$results$RMSE) # 6.268789
p_parRF2 <- predict(fit_parRF2, newdata = test2)
RMSE(p_parRF2, test2$y) # 4.812994

fit_parRF3 <- fit_parRF(data3, 1)
ggplot(fit_parRF3)
min(fit_parRF3$results$RMSE) # 6.361905
p_parRF3 <- predict(fit_parRF3, newdata = test3)
RMSE(p_parRF3, test3$y) # 5.083467

fit_parRF4 <- fit_parRF(data4, 1)
ggplot(fit_parRF4)
min(fit_parRF4$results$RMSE) # 8.705984
p_parRF4 <- predict(fit_parRF4, newdata = test4)
RMSE(p_parRF4, test4$y) # 8.083962

fit_parRF5 <- fit_parRF(data5, 1)
ggplot(fit_parRF5)
min(fit_parRF5$results$RMSE) # 8.691755
p_parRF5 <- predict(fit_parRF5, newdata = test5)
RMSE(p_parRF5, test5$y) # 7.991537


# Table - First 6 samples of train data of the 28 days model
caption <- "First 6 samples of train data of the 28 days model"
colNames = c("Cement", "B.F.S.", "Fly ash", "water",
													"Superp.", "Coarse Agg.", "Fine Agg.",
													"Wat./", "F.Agg./", "C.Agg./",
													"F.Agg./","Wat./", "Wat./", "y")
dfUnits <- c("$kg/m^3$", "$kg/m^3$","$kg/m^3$","$kg/m^3$",
													"$kg/m^3$", "$kg/m^3$","$kg/m^3$","Ce.",
													"Ce.", "Ce.", "C.Agg.", "C.Agg.", "F.Agg.", "MPa")
colNames2 = c("Features"=13, "Outcome"=1)
kable(
	head(data2),
	col.names = dfUnits,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	digits = 2,
	align = "c"
) %>%
	add_header_above(header = colNames, line = F, align = "c") %>%
	add_header_above(header = colNames2, line = T, align = "c") %>%
	kable_styling(latex_options = c("HOLD_position", "scale_down"))


# Regression models
# no dummy vars:
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
)  %>%
	kable_styling(latex_options = c("HOLD_position"))


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


# Results tables of 10 best and worst results
colNames1 = c("Actual", "Predicted", "Error", "","Actual", "Predicted", "Error")
colNames2 = c("Best 10"=3,"", "Worst 10"=3)
caption_0 <- "Model of "
get_X <- function(pred, actual, X=10){
	diff <- abs(pred - actual)
	diff_2 <- pred - actual
	ind_min <- which(diff <= max(sort(diff, decreasing = F)[1:X]), arr.ind = T)
	ind_max <- which(diff >= min(sort(diff, decreasing = T)[1:X]), arr.ind = T)
	df_min <- data.frame(
		actual_min=actual[ind_min],
		pred_min=pred[ind_min],
		diff_min=diff[ind_min],
		diff_min_2=diff_2[ind_min]
	)
	df_max <- data.frame(
		actual_max=actual[ind_max],
		pred_max=pred[ind_max],
		diff_max=diff[ind_max],
		diff_max_2=diff_2[ind_max]
	)
	df_max <- df_max[order(-df_max$diff_max),]
	df_min <- df_min[order(df_min$diff_min),]
	df_null <- data.frame(null_col = rep(c(""), X))
	res <- cbind(df_min,df_null, df_max)
	res <- res %>% select(-c(diff_max, diff_min))
	rownames(res) <- c()
	res
}
gen_kable <- function(ind){
	df <- get_X(preds[[ind]], actuals[[ind]])
	caption <- paste0(caption_0,models[ind])
	kable(
		df,
		col.names = colNames1,
		escape = F,
		booktabs = T,
		caption = caption,
		linesep = "\\addlinespace",
		align = "c"
	)  %>%
		column_spec(4, width = "1cm",) %>%
		add_header_above(header = colNames2, line = T, align = "c") %>%
		kable_styling(latex_options = c("HOLD_position"))
}
gen_kable(1)
gen_kable(2)
gen_kable(3)
gen_kable(4)
gen_kable(5)
gen_kable(6)


# Table - Comparison of other works
colNames = c("Author","Year" ,"Algorithm", "RMSE")
caption <- "Comparison of other works"
works <- data.frame(
	autor = c("Pierobon", "Hameed", "Raj","Modukuru" ,"Alshamiri", "Abban"),
	ano = c("2018", "2020", "2018","2020" ,"2020", "2016"),
	modelo = c("Ensemble com 5 algorítimos", "Artificial Neural Networks",
												"Gradient Boosting Regressor","Random Forest Regressor" ,
												"Regularized Extreme Learning Machine",
												"Support Vector Machines with Radial Basis Function Kernel"),
	RMSE = c("4.150", "4.736", "4.957","5.080","5.508", "6.105")
)
kable(
	works,
	col.names = colNames,
	escape = F,
	booktabs = T,
	caption = caption,
	linesep = "\\addlinespace",
	align = "l"
)  %>%
	kable_styling(latex_options = c("HOLD_position"))


# Table - Final results
colNames <- c("Model", "RMSE")
caption <- "Final result"
day <- c("3 days", "7 days", "14 days", "28 days", "56 days", "100 days")
dat_reg_models <- data.frame(
	dia = day,
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
)  %>%
	kable_styling(latex_options = c("HOLD_position"))
