
rm(list=ls())
hablar::set_wd_to_script_path()

library(tidyverse)

# ---------------------------------------------------------
# check behavioural data

d <- read_delim("ML02_range_gaze")
str(d)

# accuracy in decision 1 and 2
mean(d$accuracy[d$decision==1])
mean(d$accuracy[d$decision==2])

# plot
pl1 <- d %>%
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
pl2 <- d %>%
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

library(patchwork)
pl1 + pl2

# ---------------------------------------------------------
# check gaze and pupil data

dg <- read_delim("ML02_range_gaze_gaze_samples.tsv")
str(dg)

# remove practice & breaks
dg <- dg %>%
  filter(phase != "practice_intro" ) %>%
  filter(phase != "practice_trial_end" ) %>%
  filter(phase != "block_feedback" ) %>%
  filter(trial>0)

# average pupil size (from both eyes)
dg$pupil <- (dg$right_pupil_diameter +  dg$left_pupil_diameter)/2

# (note that screen resolution is 1920 x 1080 pixels)
scr_size <- c(1920, 1080)

# sampling rate (note that the devide timestamp are in microseconds)
sr <- round(1000/(median(diff(dg$device_timestamp))/1000))

# -----------------------------
# sanity checks

# scatterplot of gaze position samples during the experiment, measured in pixels
# clustered around the central fixation (as they should be)
# plot(dg$avg_x_pix[dg$left_valid & dg$right_valid], 
#      dg$avg_y_pix[dg$left_valid & dg$right_valid])


# hist(dg$pupil) # average pupil diameter ~ 3.5 mm

unique(dg$trial) # negative is for practice; why max is 300?
unique(dg$event_label)
unique(dg$phase)

count_clusters <- function(vec, label) {
  sum(rle(vec)$values == label)
}

count_clusters(dg$event_label, "fixation_on")
count_clusters(dg$event_label, "break_start")
count_clusters(dg$event_label, "stim1_on")

count_clusters(dg$phase, "decision1_stim")
count_clusters(dg$phase, "break")
# -----------------------------

# ---------------------------------------------------------
# build trial structure
# this uses also behav data loaded above
trials <- list()
trial_count <- 0L

time_window_stim1 <- c(-0.3, mean(d$RT[d$decision==1]) + 0.2 + 0.4) # stim1
# time_window_stim1 <- c(-0.25, 0.6) # response

# custom function to extract window
extract_window <- function(X, label, pre_ms = 300, post_ms = 800) {
  
  # 1) Find timestamp of first occurrence of the label
  first_idx <- which(X$phase == label)[1]
  onset_ts  <- X$device_timestamp[first_idx]
  
  # 2) Convert window to microseconds and compute indices
  pre_us  <- pre_ms  * 1000
  post_us <- post_ms * 1000
  
  window_idx <- which(
    X$device_timestamp >= (onset_ts - pre_us) &
      X$device_timestamp <= (onset_ts + post_us)
  )
  
  # 3) Time vector in seconds relative to onset (onset = 0)
  time_s <- (X$device_timestamp[window_idx] - onset_ts) / 1e6
  
  list(
    indices   = window_idx,
    time_s    = time_s,
    onset_ts  = onset_ts,
    first_idx = first_idx
  )
}

for(i in 1:max(dg$trial)){
  
  # get relevant pupil and gaze data
  X <- dg[dg$trial==i,]
  
  # this below will need to be revised when we have complete data with the event table
  all_OK <- any(X$event_label=="stim1_on") & 
    any(X$event_label=="stim2_on") &
    any(X$phase=="decision1_stim") &
    any(X$phase=="decision2_stim")
  
  if(all_OK){
    
    trial_count <- trial_count + 1
    
    # get info from d data
    rr1    <- d[d$trial==i & d$decision==1,]$response
    acc1   <- d[d$trial==i & d$decision==1,]$accuracy
    LR1    <- d[d$trial==i & d$decision==1,]$LR
    discr1 <- d[d$trial==i & d$decision==1,]$discriminability
    
    rr2    <- d[d$trial==i & d$decision==2,]$response
    acc2   <- d[d$trial==i & d$decision==2,]$accuracy
    LR2    <- d[d$trial==i & d$decision==2,]$LR
    discr2 <- d[d$trial==i & d$decision==2,]$discriminability
    
    # now get gaze data
    idx_1 <- extract_window(X, label="decision1_stim",
                            pre_ms = abs(time_window_stim1[1]*1000),
                            post_ms = time_window_stim1[2]*1000)
    pupil_1 <- X$pupil[idx_1$indices]
    gazex_1 <- X$avg_x_pix[idx_1$indices]
    gazey_1 <- X$avg_y_pix[idx_1$indices]
    time_1 <- idx_1$time_s
    
    # we should check that gaze was stable — not yet implemented
    # plot(gazex_1, scr_size[2]-gazey_1, xlim=c(0,scr_size[1]), ylim=c(0,scr_size[2]))
    
    idx_2 <- extract_window(X, label="decision2_stim")
    pupil_2 <- X$pupil[idx_2$indices]
    gazex_2 <- X$avg_x_pix[idx_2$indices]
    gazey_2 <- X$avg_y_pix[idx_2$indices]
    time_2 <- idx_1$time_s
    
    # add to trials structure
    trials[[trial_count]] <- list(
      trial_n = i,
      rr1    = rr1,
      acc1   = acc1,
      LR1    = LR1,
      discr1 = discr1,
      rr2    = rr2,
      acc2   = acc2,
      LR2    = LR2,
      discr2 = discr2,
      pupil_1 = pupil_1,
      gazex_1 = gazex_1,
      gazey_1 = gazey_1,
      time_1 = idx_1$time_s,
      pupil_2 = pupil_2,
      gazex_2 = gazex_2,
      gazey_2 = gazey_2,
      time_2 = idx_2$time_s
    )
    
    # reset values
    rr1 <- acc1 <- LR1 <- discr1 <- NA
    rr2 <- acc2 <- LR2 <- discr2 <- NA
    idx_1 <- idx_2 <- NA
    pupil_1 <- gazex_1 <- gazey_1 <- time_1 <- NA
    pupil_2 <- gazex_2 <- gazey_2 <- time_2 <- NA
    
  }
}

dg_list <- list(trial = trials)

# sanity cehck
names(dg_list$trial[[1]])

# ---------------------------------------------------------
# visualise some raw trials

trial_ids <- sample(1:trial_count, size=15)
y_rng <- range(unlist(lapply(dg_list$trial[trial_ids], function(tr) tr$pupil_1)), na.rm = TRUE)

plot(dg_list$trial[[trial_ids[1]]]$time_1, 
     dg_list$trial[[trial_ids[1]]]$pupil_1,
     type = "l", lwd = 1.5, col = "black",
     xlab = "Time from D1 stimulus onset [ms]", ylab = "Pupil area [a.u.]",
     ylim = y_rng, xlim=time_window_stim1)

for (k in trial_ids[-1]) {
  lines(dg_list$trial[[k]]$time_1, dg_list$trial[[k]]$pupil_1, lwd = 1.2)
}

abline(v = 0, lty = 2)


# ---------------------------------------------------------
# Align trials and baseline-normalize

source("signal_processing.R")
source("helper_functions.R")

# initialise
n_trials <- length(dg_list$trial)
max_len <- max(vapply(dg_list$trial, function(tr) max(c(length(tr$pupil_1), length(tr$pupil_2))), numeric(1)))
pa_matrix <- matrix(NA_real_, nrow = n_trials, ncol = max_len)
t_matrix <- matrix(NA_real_, nrow = n_trials, ncol = max_len)

for (i in seq_along(dg_list$trial)) {
  tr <- dg_list$trial[[i]]
  
  time <- tr$time_1
  pa <- tr$pupil_1

  # linearly interpolate gaps <= 300ms
  pa <- fillGap(pa, sp = 1/120, max = 250, type = "linear")
  
  # compute baseline and normalise as % change
  baseline <- mean(pa[time < 0], na.rm = TRUE)
  if (!is.finite(baseline)) next
  
  # this for percentage increase
  # pa_ok <- ((pa / baseline) - 1) * 100
  
  # mm increase in diameter
  pa_ok <- pa - baseline
  
  if (length(pa_ok) > 0) {
    pa_matrix[i, seq_along(pa_ok)] <- pa_ok
    t_matrix[i, seq_along(time)] <- time
  }
}

dim(pa_matrix)


# -----------------------------
# exploratory plots: raw traces
y_lim <- range(pa_matrix, na.rm = TRUE)
plot(NA, NA, xlim = time_window_stim1, ylim = y_lim,
     xlab = "Time [sec]", ylab = "Pupil diameter [mm change from baseline]")

# time_sec <- dg_list$trial[[i]]$time_1
time_sec <- colMeans(t_matrix, na.rm = TRUE)
pa_mean <- colMeans(pa_matrix, na.rm = TRUE)

matlines(time_sec, t(pa_matrix), lty = 1, lwd = 0.4, col = rgb(0.8, 0.8, 0.8, 0.7))
abline(v = 0, lty = 2, col = "black")
lines(time_sec, pa_mean, lwd = 2, col = "black")


# -----------------------------
# exploratory plot: smoothed mean +SE
pa_sd <- apply(pa_matrix, 2, sd, na.rm = TRUE)
n <- colSums(!is.na(pa_matrix))
sem <- pa_sd / sqrt(pmax(n, 1))

pa_mean <- colMeans(pa_matrix, na.rm = TRUE)
pa_mean_smooth <- movmean_partial(pa_mean, 6)
# time_sec <- dg_list$trial[[i]]$time_1
time_sec <- colMeans(t_matrix, na.rm = TRUE)
ok <- is.finite(pa_mean_smooth) & is.finite(sem)

ylim_all <- range(c(pa_mean_smooth[ok] - sem[ok], pa_mean_smooth[ok] + sem[ok]), na.rm = TRUE)

plot(NA, NA, xlim = time_window_stim1, ylim = ylim_all,
     xlab = "Time [sec]", ylab = "Pupil diameter [mm change from baseline]")
abline(v = 0, lty = 2, col = "black")

polygon(c(time_sec[ok], rev(time_sec[ok])),
        c(pa_mean_smooth[ok] + sem[ok], rev(pa_mean_smooth[ok] - sem[ok])),
        col = rgb(0.8, 0.8, 0.8, 0.8), border = NA)

lines(time_sec[ok], pa_mean_smooth[ok], lwd = 2, col = "black")


# -----------------------------
# plot hard vs easy trials separately
is_hard <- vapply(dg_list$trial, function(tr) tr$discr1 < 1, logical(1))

mean_easy <- colMeans(pa_matrix[!is_hard, , drop = FALSE], na.rm = TRUE)
mean_hard <- colMeans(pa_matrix[is_hard, , drop = FALSE], na.rm = TRUE)

pa_sd_easy <- apply(pa_matrix[!is_hard, , drop = FALSE], 2, sd, na.rm = TRUE)
n_easy <- colSums(!is.na(pa_matrix[!is_hard, , drop = FALSE]))
sem_easy <- pa_sd / sqrt(pmax(n, 1))

pa_sd_hard <- apply(pa_matrix[is_hard, , drop = FALSE], 2, sd, na.rm = TRUE)
n_hard <- colSums(!is.na(pa_matrix[!is_hard, , drop = FALSE]))
sem_hard <- pa_sd / sqrt(pmax(n, 1))

mean_easy_s <- movmean_partial(mean_easy, 6)
mean_hard_s <- movmean_partial(mean_hard, 6)

# time_sec <- dg_list$trial[[i]]$time_1
time_sec <- colMeans(t_matrix, na.rm = TRUE)

y_lim <- range(c(mean_easy_s, mean_hard_s), na.rm = TRUE)*1.2
plot(time_sec, mean_easy_s, type = "l", lwd = 0, col = "steelblue",
     xlab = "Time [sec]", ylab = "Pupil diameter [mm change from baseline]",
     xlim = time_window_stim1, ylim = y_lim)

polygon(c(time_sec[ok], rev(time_sec[ok])),
        c(mean_easy_s[ok] + sem_easy[ok], rev(mean_easy_s[ok] - sem_easy[ok])),
        col = rgb(0.2745098, 0.5098039, 0.7058824, 0.3), border = NA)

polygon(c(time_sec[ok], rev(time_sec[ok])),
        c(mean_hard_s[ok] + sem_hard[ok], rev(mean_hard_s[ok] - sem_hard[ok])),
        col = rgb(0.6980392, 0.1333333, 0.1333333, 0.3), border = NA)

lines(time_sec, mean_easy_s, lwd = 3, col = "steelblue")
lines(time_sec, mean_hard_s, lwd = 3, col = "firebrick")

abline(v = 0, lty = 2, col = "black")

legend("topleft", legend = c("easy (>1SD)", "hard (<1SD)"), 
       col = c("steelblue", "firebrick"), 
       lty = 1, lwd = 3, bty = "n")








