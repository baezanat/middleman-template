require "lib/path_helpers"

page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

set :url_root, ENV.fetch('BASE_URL')

ignore '/templates/*'

<%- if @langs -%>
LOCALES = ENV['LANGS'].split(",").map(&:to_sym)
activate :i18n, langs: LOCALES, mount_at_root: LOCALES[0]
<%- end -%>

activate :asset_hash
activate :directory_indexes
activate :pagination
activate :inline_svg

<%- if @token -%>
activate :dato, token: ENV.fetch('DATO_API_TOKEN'), live_reload: true
<%- end -%>

webpack_command =
  if build?
    "yarn run build"
  else
    "yarn run dev"
  end

activate :external_pipeline,
  name: :webpack,
  command: webpack_command,
  source: ".tmp/dist",
  latency: 1

configure :build do
  activate :minify_html do |html|
    html.remove_input_attributes = false
  end
  activate :search_engine_sitemap,
    default_priority: 0.5,
    default_change_frequency: 'weekly'
end

configure :development do
  activate :livereload
end

helpers do
  include PathHelpers

  def favicon_json_path(path, escape = '\/')
    image_path(path).gsub(/\//, escape)
  end

  # attributes = {class: "", id: "", data: {role: {}, title: {}}}
  def icon(name, attributes = {})
    default_attributes = {role: "icon"}
    default_attributes.merge!(attributes.except(:role))
    if attributes.key?(:class)
      default_attributes[:class] += " icon-svg--#{name}"
    else
      default_attributes[:class] ||= "icon-svg--#{name}"
    end

    content_tag(:svg, default_attributes) do
      content_tag(:use, "", "xlink:href" => "#icons-#{name}")
    end
  end
  alias_method :i, :icon

  def image_lazy(image, url_options, sizes = [], attributes = {})
    options = attributes.symbolize_keys
    url_options.merge!({auto: 'format,compress'})

    options[:title] ||= image.title
    options[:alt] ||= image.alt

    sizes_string = sizes.map do |width, size|
      "#{image.url(url_options.merge!({w: width}))} #{size}w"
    end
    options.merge!({
      data: {src: image.url(url_options), srcset: sizes_string.join(", ")}
    })

    image_tag(image.url(url_options.merge!({w: sizes.first.first})), options)
  end

  def image_tag(path, options_hash = {})
    options = options_hash.dup
    if !options.key?(:class)
      options[:class] = "lazyload"
    else
      old_class = options.delete(:class)
      options[:class] = "lazyload #{old_class}"
    end

    super(path, options)
  end

  # Custom helper to theme
  def site_nav_menu
    <%- if @token -%>
    [
      # dato.about_page,
      # dato.contact_page
    ]
    <%- else -%>
    []
    <%- end -%>
  end
end

<%- if @token -%>
# dato.tap do |dato|
#   dato.articles.each do |article|
#     proxy(
#       '/articles/#{article.slug}.html',
#       '/templates/article.html',
#       locals: { article: article }
#     )
#   end

#   paginate(
#     dato.articles.sort_by(&:published_at).reverse,
#     '/articles',
#     '/templates/articles.html'
#   )

#   MULTILANG SAMPLES
#
#   langs.each do |locale|
#     I18n.with_locale(locale) do
#       proxy "/#{locale}/index.html",
#         "/localizable/index.html",
#         locals: { page: dato.homepage },
#         locale: locale
#
#       proxy "/#{locale}/#{dato.about_page.slug}/index.html",
#         "/templates/about_page.html",
#         locals: { page: dato.about_page },
#         locale: locale
#
#       dato.aritcles.each do |article|
#         I18n.locale = locale
#         proxy "/#{locale}/articles/#{article.slug}/index.html", "/templates/article_template.html", :locals => { article: article }, ignore: true, locale: locale
#       end
#     end
#   end

#   langs.each do |locale|
#     I18n.with_locale(locale) do
#       I18n.locale = locale
#       paginate dato.articles.select{|a| a.published == true}.sort_by(&:date).reverse, "/#{I18n.locale}/articles", "/templates/articles.html", locals: { locale: I18n.locale }
#     end
#   end
# end
<%- end -%>

<%- if @langs -%>
LOCALES.each do |locale|
  I18n.with_locale(locale) do
    prefix = locale == LOCALES[0] ? "" : "/#{locale}"

    proxy "#{prefix}/index.html",
      "/localizable/index.html",
      locale: locale

    proxy "#{prefix}/contact/index.html",
      "templates/contact_page.html",
      locals: { locale: I18n.locale },
      locale: locale
  end
end
<%- end -%>

proxy "site.webmanifest",
  "templates/site.webmanifest",
  :layout => false

proxy "browserconfig.xml",
  "templates/browserconfig.xml",
  :layout => false

proxy "/_redirects",
  "/templates/redirects.txt",
  :layout => false
