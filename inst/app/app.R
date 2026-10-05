# ============================================================================
# Nobel Prize Explorer — compact two-page Shiny app
# ============================================================================

# 1. Load packages and API functions -----------------------------------------

library(shiny)
library(bslib)
library(ggplot2)
library(DT)
library(dplyr)
library(shinycssloaders)
library(nobelprizer)

#source("nobel_request.R")
# source("nobel_api.R")


# 2. Define settings and helper functions ------------------------------------

YEAR_MIN <- 1901
YEAR_MAX <- 2026

# 2.1 setting categories
CATEGORIES <- c(
  "Physics",
  "Chemistry",
  "Physiology or Medicine",
  "Literature",
  "Peace",
  "Economic Sciences"
)

# 2.2 calculate age
age_at_award <- function(birth_date, award_year) {
  birth_year <- suppressWarnings(as.integer(substr(birth_date, 1, 4)))
  award_year - birth_year
}

# 2.3 judge dead or live
death_status <- function(death_date) {
  if (is.null(death_date) || length(death_date) == 0 ||
      is.na(death_date) || death_date == "") {
    return(tags$span("——————",
                     class = "badge bg-green"))
  }
  tags$span(
    paste0("Deceased — ", death_date),
    class = "badge bg-dark"
  )
}

# 2.4 filter categories; years ; gender; unclear search.
filter_laureates <- function(df, category = "All",
                             years = c(YEAR_MIN, YEAR_MAX),
                             gender = "All", search = "") {
  if (category != "All") df <- df[df$category == category, ]
  df <- df[df$award_year >= years[1] & df$award_year <= years[2], ]
  if (gender != "All") df <- df[df$gender == gender, ]
  if (nzchar(search)) df <- df[grepl(search, df$name, ignore.case = TRUE), ]
  df
}

# 2.5 unifying the name of the country.
map_country_name <- function(x) {
  # replace standard country name
  dplyr::recode(
    x,
    "United States of America" = "USA",
    "United States" = "USA",
    "United Kingdom" = "UK",
    "Russian Federation" = "Russia",
    "Republic of Korea" = "South Korea",
    "Viet Nam" = "Vietnam",
    "Czechia" = "Czech Republic",
    .default = x
  )
}


# 3. Build the user interface -------------------------------------------------
# 3.1 create navigation
ui <- page_navbar(
  title = "Nobel Prize Explorer",
  theme = bs_theme(
    bootswatch = "flatly",
    primary = "#1F5F8B"
  ),

  # 3.2 create first navigation is overview.
  nav_panel(
    "Overview",
    # 3.2.1 left bar involve "filter", and font size
    page_sidebar(
      sidebar = sidebar(width = 300,
                        h5("Filters", style = "font-weight:700;"),
                        # 3.2.2 select six + all categories
                        selectInput("ov_cat", "Category",choices = c("All", CATEGORIES)),
                        # 3.2.3 slider year from 1901-2026
                        sliderInput(
                          "ov_years", "Year Range",
                          min = YEAR_MIN, max = YEAR_MAX,
                          value = c(YEAR_MIN, YEAR_MAX),sep = ""),
                        # 3.2.4 level seperate
                        hr(),
                        # 3.2.5 add a box show total laureates.
                        div(
                          class = "border rounded p-3 mb-3 bg-light",
                          div("Total Laureates", class = "text-muted"),
                          h4(textOutput("ov_total"), style = "margin:4px 0 0 0;")),
                        div(
                          class = "border rounded p-3 mb-3 bg-light",
                          div("Total Prize Amount", class = "text-muted"),
                          h4(textOutput("ov_amount"), style = "margin:4px 0 0 0;")),
                        # 3.2.6 add gender ratio
                        h6("Gender Distribution", style = "font-weight:700;"),
                        plotOutput("ov_gender", height = "220px")),
      # 3.2.7 card add other parts "laureates by birth country"
      card(card_header("Laureates by Birth Country"),
           withSpinner(plotOutput("ov_map", height = "360px"))),
      # 3.2.8 insert white line
      div(style = "height:8px;"),
      # 3.2.9 add over year of ages
      card(card_header("Average Age at Award Over Time"),
           withSpinner(plotOutput("ov_age", height = "360px")))
    )
  ),

  # 3.3 create other navigation
  # Laureates: compact table + larger detail panel
  nav_panel(
    "Laureates",
    page_sidebar(
      # 3.3.1 left bar involve "filter", and font size
      sidebar = sidebar(width = 300,
                        h5("Filters", style = "font-weight:700;"),
                        selectInput("la_cat", "Category",choices = c("All", CATEGORIES)),
                        sliderInput(
                          "la_years", "Year Range",
                          min = YEAR_MIN,max = YEAR_MAX,
                          value = c(YEAR_MIN, YEAR_MAX),sep = ""),
                        # 3.3.2 select according genders
                        selectInput("la_gender", "Gender",choices = c( "All","Male" = "male","Female" = "female")),
                        # 3.3.3 select according names
                        textInput("la_search", "Search Name",placeholder = "e.g. Einstein")
      ),
      # 3.3.4 add card of laureates list
      card(card_header("Laureate List"),
           withSpinner(DTOutput("la_table"))),
      div(style = "height:6px;"),
      # 3.3.5 if have some conditions which can show that.
      conditionalPanel(
        condition = "input.la_table_rows_selected.length > 0",
        # 3.3.6 dynamic create AI
        card(card_header("Laureate Detail"),uiOutput("la_detail"))
      )
    )
  )
)


# 4. Load and prepare Nobel Prize data ---------------------------------------
# 4.1 sending service and load data + add age
server <- function(input, output) {
  all_data <- reactive({
    df <- tryCatch(
      get_nobel_laureates(limit = 1050),
      error = function(e) {
        showNotification(paste("Data request failed:", e$message), type = "error")
        NULL
      })
    req(df)
    df$age <- age_at_award(df$birth_date, df$award_year)
    df
  })

  # 5. Create Overview summaries ---------------------------------------------
  # 5.1 filter overview data, according the input categories and years.
  ov_data <- reactive({
    filter_laureates(all_data(),
                     category = input$ov_cat,
                     years = input$ov_years)
  })

  # 5.2 total laureates depend on nrows
  output$ov_total <- renderText({
    nrow(ov_data())
  })

  # 5.3 total prize amount and needing delete same year and prize and just one keeping
  output$ov_amount <- renderText({
    prize_data <- ov_data() |>
      dplyr::distinct(award_year, category, .keep_all = TRUE)

    total <- sum(prize_data$prize_amount, na.rm = TRUE)
    # % 1000000 and keep one decimal
    paste0(round(total / 1e6, 1), "M SEK")
  })

  # 5.4 gender distribution, gender rely on male and female
  output$ov_gender <- renderPlot({
    d <- ov_data() |> filter(gender %in% c("male", "female")) |>
      # add new column
      count(gender) |> mutate(
        pct = n / sum(n) * 100,
        label = paste0(tools::toTitleCase(gender), "\n",  # big first one
                       n, " (", round(pct, 1), "%)"))

    req(nrow(d) > 0)
    # 5.5 ggplot graph
    ggplot(d, aes(x = "", y = n, fill = gender)) +
      geom_col(width = 1, color = "white") +
      coord_polar("y") +
      geom_text(aes(label = label),
                position = position_stack(vjust = 0.5),
                color = "white", size = 3.5) +
      scale_fill_manual(values = c(female = "#C0392B", male = "#2B5876")) +
      theme_void() +
      theme(legend.position = "none")
  })


  # 6. Draw the Overview map and age trend -----------------------------------
  # 6.1 plot country map
  output$ov_map <- renderPlot({
    counts <- ov_data() |>
      filter(!is.na(birth_country), birth_country != "") |>
      # transmute function apply
      transmute(region = map_country_name(birth_country)) |>
      count(region, name = "laureates")
    # 6.1.1 draw map according counting numbers
    world <- ggplot2::map_data("world") |>
      left_join(counts, by = "region")

    ggplot(world, aes(long, lat, group = group, fill = laureates)) +
      geom_polygon(color = "white", linewidth = 0.15) +
      coord_quickmap() +
      scale_fill_gradient(low = "#F3EEDC", high = "#14213D",
                          na.value = "#E6E6E6", name = "Laureates") +
      theme_void() +
      theme(legend.position = "bottom")
  })

  # 6.2 average age
  # similar with above
  output$ov_age <- renderPlot({
    d <- ov_data() |>
      filter(!is.na(age), age > 0, age < 120) |>
      group_by(award_year) |>
      summarise(mean_age = mean(age), .groups = "drop")

    req(nrow(d) > 0)

    ggplot(d, aes(award_year, mean_age)) +
      geom_line(linewidth = 0.9, color = "#14213D") +
      geom_point(size = 1.7, color = "#D4AF37") +
      labs(x = "Award Year", y = "Average Age") +
      theme_minimal(base_size = 12)
  })


  # 7. Build Laureates table and detail panel ---------------------------------
  # 7.1 This is second navigation first filter laureates
  la_data <- reactive({
    filter_laureates(all_data(),
                     category = input$la_cat,
                     years = input$la_years,
                     gender = input$la_gender,
                     search = input$la_search)
  })

  # 7.2 constuctor laureates table
  output$la_table <- renderDT({
    d <- la_data()
    req(nrow(d) > 0)
    # 7.2.1 according name, year and so on select
    table_data <- d |>
      select(name, award_year, category, birth_country, motivation)
    # this is data_frame show on the UI
    datatable(
      table_data,
      rownames = FALSE,
      width = "100%",
      selection = "single",
      colnames = c("Name", "Year", "Category", "Country", "Motivation"),
      options = list(
        pageLength = 8,
        autoWidth = TRUE,
        order = list(list(1, "asc")),
        columnDefs = list(
          list(width = "15%", targets = 0),
          list(width = "8%", targets = 1),
          list(width = "18%", targets = 2),
          list(width = "20%", targets = 3),
          list(
            width = "40%", targets = 4,
            render = JS(
              "function(data) {
                 if (!data) return '';
                 return data.length > 80
                   ? data.substring(0, 80) + '...'
                   : data;
               }"
            )
          )
        )
      )
    )
  })


  # 7.3 when we click one of table then show it in laureate detail
  output$la_detail <- renderUI({
    idx <- input$la_table_rows_selected
    req(idx)
    row <- la_data()[idx, ]
    # 7.3.1 if this is not value is -, it use for institution and so on
    show_value <- function(x) {
      if (is.null(x) || length(x) == 0 || is.na(x) || x == "") "—" else x
    }
    # 7.3.2 production picture
    portrait <- if ("portrait_url" %in% names(row) &&
                    !is.na(row$portrait_url) && row$portrait_url != "") {
      tags$img(
        src = row$portrait_url,
        style = "width:140px;max-height:180px;object-fit:cover;border-radius:6px;",
        onerror = "this.style.display='none'"
      )
    } else {
      icon("user-circle", style = "font-size:110px;color:#AAB2BD;")
    }
    # 7.3.3 divide two part 3:9
    layout_columns(
      col_widths = c(3, 9),
      # 7.3.3.1 this is picture on left
      div(style = "text-align:center;padding:10px;", portrait),
      # 7.3.3.2 right name and some descirbtion
      div(
        style = "padding:6px 12px;",
        # 7.3.3.2.1 name font
        h3(
          tags$a(show_value(row$name),
                 href = row$profile_url,
                 target = "_blank",
                 style = "text-decoration:none;color:inherit;"),
          style = "margin-top:0;font-weight:700;"
        ),
        # 7.3.3.2.2 add elements introduction about person
        tags$table(
          class = "table table-sm",
          tags$tbody(
            tags$tr(tags$th("Year"), tags$td(show_value(row$award_year))),
            tags$tr(tags$th("Category"), tags$td(show_value(row$category))),
            tags$tr(tags$th("Country"), tags$td(show_value(row$birth_country))),
            tags$tr(tags$th("Birth date"), tags$td(show_value(row$birth_date))),
            tags$tr(tags$th("Status"), tags$td(death_status(row$death_date))),
            tags$tr(tags$th("Age at award"), tags$td(show_value(row$age))),
            tags$tr(tags$th("Affiliation"), tags$td(show_value(row$affiliation))),
            tags$tr(tags$th("Motivation"), tags$td(show_value(row$motivation)))
          )
        )
      )
    )
  })
}
# 8. This is show it is app
shinyApp(ui = ui, server = server)
