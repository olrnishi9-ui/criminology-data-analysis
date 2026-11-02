#1.
#2a.Seattle https://data.seattle.gov/Public-Safety/SPD-Crime-Data-2008-Present/tazs-3rd5/about_data

#2b.Offense dates from Jan 1 to Oct 30, 2026, and some report dates go back to
#2023 because of late reporting. But the data includes from 2008 to present. 

#Very often, like everyday, and it was last updated at 2026/10/30

#2dYes. Seattle’s crime data blur latitude and longitude to the 100-block level,
#so coordinates represent approximate locations rather than exact incident addresses. 
#Some records also have their coordinates marked “REDACTED.”

#Yes. Only finalized, UCR-approved police reports are included. Reports still in draft, 
#awaiting approval, or completed after the latest daily update are temporarily excluded
#and may appear in subsequent updates.

#3a
# Run install.packages("data.table") once if needed
library(data.table)
options(timeout = max(300, getOption("timeout")))

# 1. Download only 2026 records
api <- "https://data.seattle.gov/resource/tazs-3rd5.csv"

query <- URLencode(
  "offense_date >= '2026-01-01T00:00:00' AND offense_date < '2027-01-01T00:00:00'",
  reserved = TRUE
)

url <- paste0(api, "?$where=", query, "&$limit=1000000")
file <- "Seattle_Crime_2026.csv"

download.file(url, destfile = file, mode = "wb")

# Report the downloaded file size
cat(sprintf("File size: %s bytes (%.2f MiB)\n",
            file.info(file)$size,
            file.info(file)$size / 1024^2))

# 2. Import using fread()
# 3. Keep identifiers, codes, and original timestamps as character
# Coordinates initially remain character because some are REDACTED
crime <- fread(
  file,
  colClasses = list(character = c(
    "report_number", "offense_id", "nibrs_offense_code",
    "reporting_area", "census_block_2020", "beat", "sector",
    "offense_date", "report_date_time", "latitude", "longitude"
  )),
  na.strings = c("", "NA", "REDACTED", "-")
)

cat("Imported:", nrow(crime), "rows and", ncol(crime), "columns\n")

# Convert coordinates and create a date column
crime[, `:=`(
  latitude = suppressWarnings(as.numeric(latitude)),
  longitude = suppressWarnings(as.numeric(longitude)),
  date = as.IDate(substr(offense_date, 1, 10))
)]

# 4. Validate the imported data

# Compare imported rows against Seattle's count for the same filter
count_url <- paste0(api, "?$select=count(*)&$where=", query)
expected_rows <- fread(count_url)$count[1]

cat("API row count:", expected_rows, "\n")

if (nrow(crime) != expected_rows) {
  warning("Row counts differ: check for truncation or a live data update.")
}

# Check that dates are valid and all records belong to 2026
stopifnot(
  nrow(crime) > 0,
  !anyNA(crime$date),
  all(crime$date >= as.IDate("2026-01-01") &
        crime$date < as.IDate("2027-01-01"))
)

cat("Date range:", format(min(crime$date)), "to",
    format(max(crime$date)), "\n")

# Check missing values in each column
print(colSums(is.na(crime)))

# Inspect monthly counts for unusually low or missing months
print(
  crime[, .N, by = .(month = format(date, "%Y-%m"))][order(month)]
)

# Find dates with zero records, excluding today and future dates
graphics.off()
expected_days <- seq(
  as.IDate("2026-01-01"),
  min(as.IDate(Sys.Date() - 1), as.IDate("2026-12-31")),
  by = "day"
)

missing_days <- expected_days[!expected_days %in% crime$date]

cat("Dates with zero records:\n")
print(missing_days)

# Flag missing coordinates or points outside a generous Seattle area
crime[, valid_coordinates :=
        !is.na(latitude) & !is.na(longitude) &
        between(latitude, 47.4, 47.8) &
        between(longitude, -122.5, -122.2)]

print(crime[, .N, by = valid_coordinates])

# Check repeated report/offense pairs
cat("Repeated report/offense pairs:",
    sum(duplicated(crime, by = c("report_number", "offense_id"))),
    "\n")


#4
input_file <- file
library(data.table)
library(sf)
library(ggplot2)

options(timeout = max(180, getOption("timeout")))
setDTthreads(min(4L, getDTthreads()))

out <- "seattle_results"
dir.create(file.path(out, "cache"),
           recursive = TRUE, showWarnings = FALSE)

start_date <- as.IDate("2026-01-01")
end_date   <- as.IDate("2026-10-30")
years <- (as.numeric(end_date - start_date) + 1) / 365

hex_m       <- 500
bandwidth_m <- 500
pixel_m     <- 100

focus <- NULL

save_csv <- function(x, name) {
  fwrite(x, file.path(out, paste0(name, ".csv")))
}

#4a
input_file <- file.choose()
crime_raw <- fread(
  input_file,
  colClasses = "character",
  na.strings = NULL
)

crime <- copy(crime_raw)

crime[, names(crime) := lapply(.SD, function(x) {
  x <- trimws(x)
  x[toupper(x) %chin% c("", "NA", "-", "REDACTED")] <- NA_character_
  x
})]

crime[, `:=`(
  latitude_raw  = crime_raw$latitude,
  longitude_raw = crime_raw$longitude
)]

if (anyNA(crime$report_number) || anyNA(crime$offense_id)) {
  stop("Missing identifiers: inspect crime_raw before merging records.")
}

keys <- c("report_number", "offense_id")

dups <- crime[, .N, by = keys][N > 1]
duplicate_rows <- crime[dups, on = keys]

save_csv(duplicate_rows, "duplicate_review")

other_fields <- setdiff(names(crime), "shooting_type_group")

conflicts <- unique(
  duplicate_rows[, ..other_fields]
)[, .N, by = keys][N > 1]

if (nrow(conflicts)) {
  stop("Conflicting offense records: inspect duplicate_review.csv.")
}

if (nrow(dups)) {
  merged_labels <- duplicate_rows[
    , .(shooting_type_group = {
      z <- sort(unique(na.omit(shooting_type_group)))
      if (length(z)) paste(z, collapse = " | ") else NA_character_
    }),
    by = keys
  ]
  
  crime[
    merged_labels,
    on = keys,
    shooting_type_group := i.shooting_type_group
  ]
}

crime <- unique(crime, by = keys)
crime[, row_id := .I]

cat("Original rows:", nrow(crime_raw), "\n")
cat("Unique offenses:", nrow(crime), "\n")

#4b–4c
crime[, `:=`(
  date = as.IDate(substr(offense_date, 1, 10)),

  occurred_at = as.POSIXct(
    offense_date,
    format = "%Y-%m-%dT%H:%M:%OS",
    tz = "America/Los_Angeles"
  ),

  reported_at = as.POSIXct(
    report_date_time,
    format = "%Y-%m-%dT%H:%M:%OS",
    tz = "America/Los_Angeles"
  ),

  latitude  = suppressWarnings(as.numeric(latitude)),
  longitude = suppressWarnings(as.numeric(longitude)),

  offense_sub_category = toupper(offense_sub_category)
)]

crime[, date_ok :=
        !is.na(date) & date >= start_date & date <= end_date]

crime[, time_review :=
        is.na(reported_at) |
        (!is.na(occurred_at) & reported_at < occurred_at)]

save_csv(crime[!date_ok | time_review], "date_review")

crime[, in_scope :=
        !is.na(nibrs_offense_code) &
        nibrs_offense_code != "999" &
        !is.na(offense_sub_category) &
        !is.na(nibrs_crime_against_category) &
        nibrs_crime_against_category != "NOT_A_CRIME"]

if (!is.null(focus)) {
  crime[, in_scope :=
          in_scope & offense_sub_category %chin% toupper(focus)]
}

print(crime[, .N, by = offense_sub_category][order(-N)])

save_csv(
  crime[date_ok == TRUE,
        .N,
        by = .(month = format(date, "%Y-%m"))][order(month)],
  "monthly_counts"
)

all_days <- seq(start_date, end_date, by = "day")

save_csv(
  data.table(date = all_days[!all_days %in% crime$date]),
  "dates_with_zero_records"
)

#4d-4e
crime[, coordinate_status := fcase(
  toupper(trimws(latitude_raw)) %chin% "REDACTED" |
    toupper(trimws(longitude_raw)) %chin% "REDACTED",
  "redacted",
  
  is.na(latitude) | is.na(longitude),
  "missing_or_not_numeric",
  
  !is.finite(latitude) | !is.finite(longitude) |
    !between(latitude, -90, 90) |
    !between(longitude, -180, 180),
  "invalid_global_range",
  
  latitude == -1 & longitude == -1,
  "placeholder_minus_one",
  
  latitude == 0 & longitude == 0,
  "placeholder_zero",
  
  !between(latitude, 47.4, 47.8) |
    !between(longitude, -122.5, -122.2),
  "outside_broad_bbox",
  
  default = "candidate"
)]

boundary_file <- file.path(out, "cache", "seattle_districts.geojson")

boundary_url <- paste0(
  "https://services.arcgis.com/ZOyb2t4B0UYuYNYH/arcgis/rest/services/",
  "Seattle_City_Council_Districts/FeatureServer/0/query?",
  "where=1%3D1&outFields=*&outSR=4326&f=geojson"
)

if (!file.exists(boundary_file)) {
  download.file(
    boundary_url, boundary_file,
    mode = "wb", quiet = TRUE
  )
}

districts <- st_read(boundary_file, quiet = TRUE)

stopifnot(
  nrow(districts) == 7,
  !any(st_is_empty(districts))
)

city <- st_sf(
  geometry = st_union(
    st_make_valid(st_transform(districts, 26910))
  )
)

pts <- st_as_sf(
  crime[coordinate_status == "candidate",
        .(row_id, longitude, latitude)],
  coords = c("longitude", "latitude"),
  crs = 4326
)

pts <- st_transform(pts, st_crs(city))

inside <- lengths(st_intersects(pts, city)) > 0

# Review points outside the land study area
outside_pts <- pts[!inside, ]

if (nrow(outside_pts) > 0L) {
  boundary_review <- copy(crime[outside_pts$row_id])
  
  boundary_review[, distance_to_land_m :=
                    as.numeric(st_distance(outside_pts, city))]
  
  # Review only offenses within the analysis period and scope
  boundary_review <- boundary_review[date_ok & in_scope]
  
  boundary_review[, near_boundary_100m :=
                    distance_to_land_m <= 100]
  
  save_csv(boundary_review, "boundary_review")
  
  print(boundary_review[, .N, by = near_boundary_100m])
}

# Outside-land records are retained for review and excluded from maps.
# Near-boundary locations may reflect block-level coordinate blurring.

crime[pts$row_id, coordinate_status := ifelse(
  inside,
  "inside_study_area",
  "outside_land_mask_review"
)]

crime[, map_status := fcase(
  !date_ok,
  "outside_period_or_missing_date",
  
  !in_scope,
  "outside_offense_scope",
  
  coordinate_status != "inside_study_area",
  coordinate_status,
  
  default = "mapped"
)]

pts <- pts[
  pts$row_id %in% crime[map_status == "mapped", row_id],
]

stopifnot(nrow(pts) > 0)

print(crime[, .N, by = map_status])

save_csv(crime, "cleaned_offenses")
save_csv(crime[map_status != "mapped"], "excluded_from_maps")
save_csv(crime[, .N, by = map_status], "map_exclusion_summary")

save_csv(
  crime[, .N, by = .(coordinate_status, in_scope)],
  "coordinate_audit"
)

save_csv(
  crime[
    , .(offenses = .N, mapped = sum(map_status == "mapped")),
    by = .(offense_sub_category, nibrs_offense_code_description)
  ],
  "category_audit"
)

#5a
make_hex <- function(size) {
  
  grid <- st_make_grid(
    city,
    cellsize = size,
    square = FALSE
  )
  
  h <- suppressWarnings(
    st_intersection(
      st_sf(hex_id = seq_along(grid), geometry = grid),
      city
    )
  )
  
  h$area_km2 <- as.numeric(st_area(h)) / 1e6
  h <- h[h$area_km2 > 0, ]
  
  hits <- st_intersects(pts, h)
  
  cell <- vapply(
    hits,
    function(i) if (length(i)) i[1L] else NA_integer_,
    integer(1)
  )
  
  stopifnot(!anyNA(cell))
  
  h$count <- tabulate(cell, nbins = nrow(h))
  
  # offenses / km² / year
  h$density <- h$count / h$area_km2 / years
  
  h$small_edge <- h$area_km2 <
    0.10 * sqrt(3) / 2 * (size / 1000)^2
  
  h$density[h$small_edge] <- NA_real_
  
  stopifnot(sum(h$count) == nrow(pts))
  
  attr(h, "point_cell") <- cell
  h
}

hex <- make_hex(hex_m)

hex_map <- ggplot(hex) +
  geom_sf(aes(fill = density), color = NA) +
  geom_sf(
    data = hex[hex$count == 0 & !hex$small_edge, ],
    fill = "grey85",
    color = NA
  ) +
  scale_fill_viridis_c(
    option = "magma",
    direction = -1,
    trans = "sqrt",
    na.value = "grey60",
    name = "Offenses\nper km² per year"
  ) +
  coord_sf(datum = NA) +
  labs(
    title = "Seattle crime hotspots: hexagons",
    subtitle = paste(start_date, "to", end_date),
    caption = "Light gray: zero mapped offenses. Dark gray: rate not estimated."
  ) +
  theme_void()

print(hex_map)

#5b
xy <- st_coordinates(pts)

# 相同坐标合并为权重，保留该位置的全部犯罪次数
weighted_xy <- data.table(
  x = xy[, 1],
  y = xy[, 2]
)[, .(weight = .N), by = .(x, y)]

window <- spatstat.geom::as.owin(st_geometry(city))

pattern <- spatstat.geom::ppp(
  weighted_xy$x,
  weighted_xy$y,
  window = window,
  checkdup = FALSE
)

stopifnot(
  pattern$n == nrow(weighted_xy),
  sum(weighted_xy$weight) == nrow(pts)
)

make_kde <- function(bandwidth) {
  
  z <- spatstat.explore::density.ppp(
    pattern,
    sigma = bandwidth,
    eps = pixel_m,
    weights = weighted_xy$weight,
    wtype = "multiplicity",
    edge = TRUE,
    positive = TRUE
  )
  
  # offenses/m²/观察期 → offenses/km²/year
  z$v <- z$v * 1e6 / years
  z
}

kde <- make_kde(bandwidth_m)

# 两种地图采用一致的密度区间
breaks <- c(0, 100, 250, 500, 1000, 2000, 4000, 8000, Inf)

band_labels <- c(
  ">0-100", "100-250", "250-500", "500-1,000",
  "1,000-2,000", "2,000-4,000", "4,000-8,000", "8,000+"
)

to_bands <- function(z) {
  
  v <- z$v
  missing <- !is.finite(v)
  
  # 仅为闭合等值带延伸窗口外的值，最后仍裁剪回陆地边界
  # 有效KDE像素和犯罪位置均保持不变
  if (any(missing)) {
    
    g <- expand.grid(y = z$yrow, x = z$xcol)
    box <- spatstat.geom::owin(z$xrange, z$yrange)
    
    a <- spatstat.geom::ppp(
      g$x[missing], g$y[missing],
      window = box, checkdup = FALSE
    )
    
    b <- spatstat.geom::ppp(
      g$x[!missing], g$y[!missing],
      window = box, checkdup = FALSE
    )
    
    nearest <- spatstat.geom::nncross(a, b, what = "which")
    v[missing] <- v[!missing][nearest]
  }
  
  # 补齐最外侧半个像素，避免城市边缘出现空白带
  x <- c(z$xcol[1] - z$xstep,
         z$xcol,
         tail(z$xcol, 1) + z$xstep)
  
  y <- c(z$yrow[1] - z$ystep,
         z$yrow,
         tail(z$yrow, 1) + z$ystep)
  
  v <- v[
    c(1, seq_len(nrow(v)), nrow(v)),
    c(1, seq_len(ncol(v)), ncol(v))
  ]
  
  iso <- isoband::isobands(
    x, y, v,
    levels_low = head(breaks, -1),
    levels_high = tail(breaks, -1)
  )
  
  s <- st_sf(
    band = factor(band_labels, levels = band_labels),
    geometry = st_sfc(
      isoband::iso_to_sfg(iso),
      crs = st_crs(city)
    )
  )
  
  s <- st_make_valid(s[!st_is_empty(s), ])
  s <- suppressWarnings(st_intersection(s, city))
  
  # 确认密度带覆盖整个分析范围
  stopifnot(
    abs(sum(as.numeric(st_area(s))) -
          as.numeric(st_area(city))) < 1
  )
  
  s
}

bands <- to_bands(kde)

kde_map <- ggplot(bands) +
  geom_sf(aes(fill = band), color = NA) +
  scale_fill_viridis_d(
    option = "magma",
    direction = -1,
    drop = FALSE,
    name = "Offenses\nper km² per year"
  ) +
  coord_sf(datum = NA) +
  labs(
    title = "Seattle crime hotspots: KDE",
    subtitle = paste(start_date, "to", end_date)
  ) +
  theme_void()

print(kde_map)

#5c
# 找出5个高密度格子：至少10个offense，彼此相距至少1公里
centres <- suppressWarnings(st_point_on_surface(hex))
cx <- st_coordinates(centres)
chosen <- integer()

for (i in order(hex$density, decreasing = TRUE, na.last = NA)) {
  
  separated <- all(
    rowSums(
      (t(t(cx[chosen, , drop = FALSE]) - cx[i, ]))^2
    ) >= 1000^2
  )
  
  if (hex$count[i] >= 10 && separated) {
    chosen <- c(chosen, i)
  }
  
  if (length(chosen) == 5) break
}

hotspots <- centres[chosen, ]
hotspots$rank <- seq_along(chosen)

# 为热点添加格子内最常见的社区名称
pinfo <- crime[pts$row_id, .(neighborhood)]
pinfo[, cell := attr(hex, "point_cell")]

dominant <- pinfo[
  , .N, by = .(cell, neighborhood)
][order(cell, -N)][, .SD[1], by = cell]

hotspots$neighborhood <- dominant$neighborhood[
  match(chosen, dominant$cell)
]

ll <- st_coordinates(st_transform(hotspots, 4326))

save_csv(
  data.table(
    rank = hotspots$rank,
    neighborhood = hotspots$neighborhood,
    offenses = hotspots$count,
    area_km2 = hotspots$area_km2,
    annualized_density = hotspots$density,
    longitude = ll[, 1],
    latitude = ll[, 2]
  ),
  "hotspot_locations"
)

# 明确区分零计数、正密度和无法稳定估计的边缘格子
zero_label <- "0 mapped offenses"
edge_label <- "No estimate: small edge cell"

palette <- setNames(
  viridisLite::magma(length(band_labels), direction = -1),
  band_labels
)

palette <- c(
  setNames("#D9DEDF", zero_label),
  palette,
  setNames("#9CA9AF", edge_label)
)

class_hex <- function(h) {
  
  b <- as.character(cut(
    h$density,
    breaks,
    labels = band_labels,
    include.lowest = TRUE,
    right = FALSE
  ))
  
  b[h$count == 0 & !h$small_edge] <- zero_label
  b[h$small_edge] <- edge_label
  
  h$band <- factor(
    b,
    levels = c(zero_label, band_labels, edge_label)
  )
  
  h
}

hex <- class_hex(hex)
bb <- st_bbox(city)

period_text <- sprintf(
  "%s to %s | %s mapped offenses | annualized rate",
  format(start_date),
  format(end_date),
  format(nrow(pts), big.mark = ",")
)

hotspot_key <- paste(
  paste0(
    hotspots$rank, " ",
    tools::toTitleCase(tolower(hotspots$neighborhood))
  ),
  collapse = " | "
)

caption <- paste0(
  "Source: Seattle Police Department; Seattle GIS shoreline-clipped council districts.\n",
  "Block-blurred locations; unlocated records excluded, not treated as zero. ",
  "Blue-gray: outside land study area.\n",
  "Markers: five separated high-intensity hexagons. ",
  "Descriptive intensity, not population-adjusted risk.\n",
  paste(
    strwrap(paste("Hotspots:", hotspot_key), width = 115),
    collapse = "\n"
  )
)

draw_map <- function(s, title, method, markers = TRUE) {
  
  p <- ggplot() +
    geom_sf(data = city, fill = "#9CA9AF", color = NA) +
    geom_sf(
      data = s,
      aes(fill = band),
      color = NA,
      show.legend = TRUE
    ) +
    geom_sf(
      data = city,
      fill = NA,
      color = "#657780",
      linewidth = 0.24
    ) +
    scale_fill_manual(
      values = palette,
      drop = FALSE,
      name = "Reported offenses\nper km² per year"
    ) +
    labs(
      title = title,
      subtitle = paste(period_text, method, sep = "\n"),
      caption = caption
    ) +
    annotate(
      "segment",
      x = bb["xmin"] + 900,
      xend = bb["xmin"] + 900,
      y = bb["ymax"] - 2300,
      yend = bb["ymax"] - 900,
      arrow = grid::arrow(length = grid::unit(0.14, "inches")),
      linewidth = 0.5
    ) +
    annotate(
      "text",
      x = bb["xmin"] + 900,
      y = bb["ymax"] - 500,
      label = "N",
      size = 3.5
    ) +
    annotate(
      "segment",
      x = bb["xmin"] + 900,
      xend = bb["xmin"] + 2900,
      y = bb["ymin"] + 700,
      yend = bb["ymin"] + 700,
      linewidth = 1.2
    ) +
    annotate(
      "text",
      x = bb["xmin"] + 1900,
      y = bb["ymin"] + 1200,
      label = "2 km",
      size = 3
    ) +
    theme_void(base_size = 11) +
    theme(
      panel.background = element_rect(fill = "#EDF3F6", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.title = element_text(
        size = 21, face = "bold", color = "#172B3A",
        margin = margin(b = 7)
      ),
      plot.subtitle = element_text(
        size = 10, color = "#52636D",
        lineheight = 1.3, margin = margin(b = 12)
      ),
      plot.caption = element_text(
        size = 8, color = "#52636D", hjust = 0,
        lineheight = 1.25, margin = margin(t = 12)
      ),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 9),
      legend.key.height = grid::unit(0.5, "cm"),
      plot.margin = margin(18, 18, 16, 18)
    )
  
  geom_sf(
    data = s,
    aes(fill = band),
    color = NA,
    show.legend = TRUE
  )
  
  if (markers) {
    p <- p +
      geom_sf(
        data = hotspots,
        shape = 21, fill = "white",
        color = "#172B3A", size = 4.6
      ) +
      geom_sf_text(
        data = hotspots,
        aes(label = rank),
        size = 2.7, fontface = "bold",
        color = "#172B3A"
      )
  }
  
  p + coord_sf(
    crs = st_crs(city),
    datum = NA,
    xlim = c(bb["xmin"] - 1000, bb["xmax"] + 1000),
    ylim = c(bb["ymin"] - 400, bb["ymax"] + 400),
    expand = FALSE
  )
}

hex_map <- draw_map(
  hex,
  "Seattle crime hotspots: hexagons",
  sprintf("%s m hexagons | clipped land area denominator", hex_m)
)

kde_map <- draw_map(
  bands,
  "Seattle crime hotspots: KDE",
  sprintf(
    "Gaussian bandwidth %s m | %s m pixels | edge corrected",
    bandwidth_m, pixel_m
  )
)

# 显示地图
print(hex_map)
print(kde_map)
dev.off()
# Save the finished maps as 300-dpi images
ggsave(
  file.path(out, "seattle_hexagons.png"),
  hex_map,
  width = 9, height = 10.5, dpi = 300, bg = "white"
)

ggsave(
  file.path(out, "seattle_kde.png"),
  kde_map,
  width = 9, height = 10.5, dpi = 300, bg = "white"
)

save_csv(st_drop_geometry(hex), "hexagon_intensity")
