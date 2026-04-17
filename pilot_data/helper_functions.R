vecvel <- function(xx, sampling, type = 2L) {
  if (!is.matrix(xx)) {
    xx <- as.matrix(xx)
  }
  n <- nrow(xx)
  v <- matrix(0, n, 2)
  if (type == 1L) {
    if (n >= 3L) {
      v[2:(n - 1), ] <- (sampling / 2) * (xx[3:n, ] - xx[1:(n - 2), ])
    }
  } else if (type == 2L) {
    if (n >= 5L) {
      v[3:(n - 2), ] <- (sampling / 6) * (
        xx[5:n, ] + xx[4:(n - 1), ] - xx[2:(n - 3), ] - xx[1:(n - 4), ]
      )
    }
    if (n >= 3L) {
      v[2, ] <- (sampling / 2) * (xx[3, ] - xx[1, ])
      v[n - 1, ] <- (sampling / 2) * (xx[n, ] - xx[n - 2, ])
    }
  } else {
    stop("type must be 1 or 2")
  }
  v
}


movmean_partial <- function(x, k) {
  n <- length(x)
  left <- floor((k - 1) / 2)
  right <- k - 1 - left
  out <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    lo <- max(1L, i - left)
    hi <- min(n, i + right)
    w <- x[lo:hi]
    out[i] <- if (all(is.na(w))) NA_real_ else mean(w, na.rm = TRUE)
  }
  out
}