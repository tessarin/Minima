<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>[% view.title %]</title>
%% if view.settings.block_indexing
  <meta name="robots" content="noindex">
%% end
%% if view.description
  <meta name="description" content="[% view.description %]">
%% end
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
%% if view.settings.theme_color
  <meta name="theme-color" content="[% view.theme_color %]">
%% end
@@ IF static
  <link rel="stylesheet" href="/css/main.css" />
@@ END
</head>
<body>

%% foreach p in view.pre_body
%%   include $p
%% end

<main class="[% view.classes %]">
