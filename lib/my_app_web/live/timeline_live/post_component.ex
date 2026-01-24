defmodule MyAppWeb.TimelineLive.PostComponent do
  use MyAppWeb, :live_component

  def render(assigns) do
      ~H"""
      <div id={"post-#{@id}"} class="bg-white p-6 border border-gray-200 rounded-xl shadow-sm transition hover:border-blue-300">
        <div class="flex items-start space-x-4">
          <%!-- Avatar --%>

          <div class="w-[95px] h-[95px] bg-indigo-50 border-2 border-indigo-100 rounded-full flex items-center justify-center text-center flex-shrink-0" >
            <span class="text-gray-500 font-bold text-center">{@post.username |> String.at(0) |> String.upcase()}</span>
          </div>


          <div class="flex-1 border-2 border-gray-200 p-4" style="border-color: #0011;">
            <div class="flex justify-between items-start">
              <div>
                <span class="font-bold text-gray-900 text-lg">@{@post.username}</span>
                <p class="text-gray-800 mt-1 leading-relaxed">{@post.body}</p>
              </div>
            </div>

            <%!-- Barre d'actions --%>
            <div class="mt-4 pt-4 border-t border-gray-50 flex items-center justify-between text-gray-500">
              <div class="flex space-x-8">
                <button class="flex items-center space-x-2 hover:text-red-500 transition">
                  <.icon name="hero-heart" class="w-5 h-5" />
                  <span class="text-sm font-medium">{@post.likes_count}</span>
                </button>

                <button class="flex items-center space-x-2 hover:text-green-500 transition">
                  <.icon name="hero-arrow-path" class="w-5 h-5" />
                  <span class="text-sm font-medium">{@post.reposts_count}</span>
                </button>
              </div>

              <div class="flex space-x-3">
                <.link patch={~p"/post/#{@post}/edit"} class="p-2 hover:bg-blue-50 rounded-full text-blue-500">
                  <.icon name="hero-pencil-square" class="w-5 h-5" />Edit
                </.link>

                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={@post.id}
                  data-confirm="Supprimer ?"
                  class="p-2 hover:bg-red-50 rounded-full text-red-500"
                >
                  <.icon name="hero-trash" class="w-5 h-5" />Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      """
    end
end
