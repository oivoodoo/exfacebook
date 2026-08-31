defmodule Exfacebook.Config do
  @moduledoc """
  Runtime configuration for Graph API version and app credentials.
  """

  @default_api_version "v26.0"
  @default_graph_url "https://graph.facebook.com"
  @default_graph_video_url "https://graph-video.facebook.com"

  @doc """
  Graph API version used in request paths.

  Defaults to `v26.0`, the current Graph API version as of 2026-07-29.
  See https://developers.facebook.com/docs/graph-api/changelog/versions/
  """
  def api_version do
    Application.get_env(:exfacebook, :api_version, @default_api_version)
  end

  @doc """
  Base Graph API host. Defaults to `https://graph.facebook.com`.
  """
  def graph_url do
    Application.get_env(:exfacebook, :graph_url, @default_graph_url)
  end

  @doc """
  Host used for video uploads. Defaults to `https://graph-video.facebook.com`.
  """
  def graph_video_url do
    Application.get_env(:exfacebook, :graph_video_url, @default_graph_video_url)
  end

  @doc """
  Facebook app secret, used to sign requests with `appsecret_proof`.
  """
  def secret do
    Application.get_env(:exfacebook, :secret)
  end

  @doc """
  Facebook app id, used to build app access tokens (`id|secret`).
  """
  def id do
    Application.get_env(:exfacebook, :id)
  end
end
