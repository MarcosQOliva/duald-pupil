
rm(list=ls())
hablar::set_wd_to_script_path()

library(tidyverse)

# ---------------------------------------------------------
# check behavioural data

d <- read_delim("ML01_range_gaze")
str(d)

# accuracy in decision 1 and 2
mean(d$accuracy[d$decision==1])
mean(d$accuracy[d$decision==2])

# plot
d %>%
  select(decision, accuracy, trial) %>%
  pivot_wider(id_cols=trial,
              names_from = decision,
              values_from = accuracy,
              names_prefix = "acc") %>%
  summarise(acc1_se = mlisi::binomSEM((acc1)),
            acc2_se = mlisi::binomSEM((acc2)),
            acc1 = mean(acc1),
            acc2 = mean(acc2)) %>%
  ggplot(aes(x=acc1, y=acc2))+
  geom_errorbar(aes(ymin=acc2-acc2_se, ymax=acc2+acc2_se), width=0) +
  geom_errorbar(aes(xmin=acc1-acc1_se, xmax=acc1+acc1_se), orientation="y", width=0) +
  geom_point()+
  geom_abline(intercept = 0, 
              slope=1,
              lty=2) +
  coord_equal(xlim=c(0.5,1), ylim=c(0.5,1))+
  labs(x="accuracy decision 1",
       y="accuracy decision 2")

# estimate sensory noise based only on decision 1
d$LR <- log(d$n_right) - log(d$n_left)
m0 <- glm(response ~ LR, d[d$decision==1,], family=binomial("probit"))
eta <- 1/coef(m0)["LR"] # this is the SD of internal noise

# discriminability of stimuli expressed in SD of internal noise
d$discriminability <- abs(d$LR)/eta

# plot accuracy as a function of discriminability
d$decision <- factor(d$decision)
d %>%
  mutate(difficulty_bin = cut_interval(discriminability, 5)) %>%
  group_by(difficulty_bin, decision) %>%
  summarise(discriminability = mean(discriminability),
            se = mlisi::binomSEM(accuracy),
            accuracy=mean(accuracy)) %>%
  ggplot(aes(x=discriminability, y=accuracy, 
             group = decision, color=decision)) +
  geom_point()+
  geom_errorbar(aes(ymin=accuracy-se, ymax=accuracy+se), width=0)+
  geom_smooth(data=d, method = "glm",
              method.args=list(family=binomial(link="probit")),
              se=FALSE)

# ---------------------------------------------------------
# check gaze and pupil data

dg <- read_delim("ML01_range_gaze_gaze_samples.tsv")
str(dg)

# remove practice & breaks
dg <- dg %>%
  filter(phase != "practice_intro" ) %>%
  filter(phase != "practice_trial_end" ) %>%
  filter(phase != "block_feedback" ) %>%
  filter(trial>0)

# average pupil size (from both eyes)
dg$pupil <- (dg$right_pupil_diameter +  dg$left_pupil_diameter)/2
# hist(dg$pupil) # average pupil diameter ~ 3.5 mm

# scatterplot of gaze position samples during the experiment, measured in pixels
# clustered around the central fixation (as they should be)
plot(dg$avg_x_pix[dg$left_valid & dg$right_valid], 
     dg$avg_y_pix[dg$left_valid & dg$right_valid])

# sanity checks
unique(dg$trial) # negative is for practice; why max is 300?
unique(dg$event_label)
unique(dg$phase)

count_clusters <- function(vec, label) {
  sum(rle(vec)$values == label)
}

count_clusters(dg$event_label, "fixation_on")
count_clusters(dg$event_label, "break_start")

count_clusters(dg$phase, "decision1_stim")
count_clusters(dg$phase, "break")

# build trial structure
# this uses also behav data loaded above
trials <- list()
trial_counter <- 0L

# trial_n <- NA_integer_
# t_start <- NA_integer_
# t_end <- NA_integer_
# t_fix <- NA_integer_

for(i in 1:max(dg$trial)){
  
  # get info from d data
  
  
}






