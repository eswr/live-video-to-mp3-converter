defmodule LiveMediaWeb.Live.HomePage do
  use LiveMediaWeb, :live_view

  alias LiveMedia.Video

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar, accept: ~w(.mp4 .avi .mov .wmv), max_entries: 1)
     |> assign(:audio_path, nil)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        if path && File.exists?(path) do
          case Video.to_audio(path) do
            {:error, :conversion_failed, message, _} -> {:error, message}
            {:ok, result} -> {:ok, result}
          end
        else
          {:error, "Invalid file path"}
        end
      end)

    # Ensure we have at least one valid file path before calling String.split/3
    file_name =
      case List.first(uploaded_files) do
        nil -> nil
        file_path when is_binary(file_path) -> List.last(String.split(file_path, "/"))
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(:uploaded_files, uploaded_files)
     |> assign(:audio_path, if(file_name, do: "/uploads/#{file_name}", else: nil))}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
