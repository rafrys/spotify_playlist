truncate <- function(playlist_id, authorization){
  # Remove all songs from playlist but keep the playlist.
  # Returns invisibly list of previous track uri's
  
  # Check if playlist id is char with length 1 
  stopifnot(is.character(playlist_id))
  stopifnot(length(playlist_id) == 1)
  
  # Check if token correct
  if (!inherits(authorization, "R6")) stop("authorization method is incorrect (not Token)")
  
  # 
  previous_tracks <- get_playlist_tracks(playlist_id = playlist_id, 
                      authorization = authorization$credentials$access_token)
  
  if (length(previous_tracks) == 0){
    warning("There were no tracks on the playlist")
    return(invisible(NULL))
  }
  
  previous_tracks_uris <- previous_tracks$track.uri
  
  if (is.null(previous_tracks_uris)){
    warning("There were no tracks on the playlist")
    return(invisible(NULL))
  }
  
  
  remove_tracks_from_playlist(playlist_id, 
                              previous_tracks_uris, 
                              authorization = authorization)
  
  invisible(previous_tracks_uris)
}

union_playlists <- function(foreign_playlist_uris,
                            my_playlist_uri,
                            authorization =
                              spotifyr::get_spotify_authorization_code()) {
  # Function copies speicified multiple playlists to one playlist created by the user 
  # foreign_playlist_uris - from which to copy
  # my_playlist_uri - use existing user playlist
  # append - if true, append tracks from other playlist to existing playlist
  # if false, truncate all songs and replace playlist details (description, name)
  
  if (length(foreign_playlist_uris) == 0){
    stop("No playlists to copy from")
  }
  
  for (i in 1:length(foreign_playlist_uris)){
    fork_foreign_playlist(foreign_playlist_uris[i],
                          my_playlist_uri,
                          append = TRUE,
                          authorization = access_token)
  }
  
}


fork_foreign_playlist <- function(foreign_playlist_uri,
                                  my_playlist_uri = NULL,
                                  append = FALSE,
                                  user_id = NULL,
                                  authorization =
                                    spotifyr::get_spotify_authorization_code()) {
  # Foreign playlist - from which to copy
  # my_playlist_uri - if not null, use existing user playlist
  # append - if true, append tracks from other playlist to existing playlist
  # if false, truncate all songs and replace playlist details (description, name)
  check_args(foreign_playlist_uri,
             my_playlist_uri,
             append,
             user_id)
  # Get details of foreign playlist - name, desc, tracks
  foreign_playlist_data <- get_playlist(
    foreign_playlist_uri,
    authorization = authorization$credentials$access_token ,
    fields = c("description", "name", "tracks.items.track.uri")
  )
  
  foreign_tracks_uris <-
    foreign_playlist_data$tracks$items$track.uri
  
  if (length(foreign_tracks_uris) == 0) {
    warning("No tracks on foreign playlist. Aborting")
    return(NULL)
  }
  
  # if new playlist,
  # populate with songs
  # return new_playlist ur
  # if old playlist and append
  # add tracks
  if (is.null(my_playlist_uri)){
    created_playlist_info <- create_playlist(user_id = user_id, 
                                             name = foreign_playlist_data$name,
                                             description = foreign_playlist_data$description,
                                             authorization = authorization
    )
    add_tracks_to_playlist(created_playlist_info$id, foreign_tracks_uris, authorization = authorization)
    
    return(invisible(foreign_tracks_uris))
  }
  
  
  # if old and append
  if (append) {
    add_tracks_to_playlist(my_playlist_uri, foreign_tracks_uris, authorization = authorization)
    return(invisible(foreign_tracks_uris))
  }
  
  
  # if old and not append
  # truncate playlist
  # add tracks
  # replace details
  if (!is.null(my_playlist_uri) && !append) {
    suppressWarnings(truncate(my_playlist, authorization))
    add_tracks_to_playlist(my_playlist_uri,
                           foreign_tracks_uris,
                           authorization = authorization)
    change_playlist_details(
      my_playlist_uri,
      name = foreign_playlist_data$name,
      description = foreign_playlist_data$description,
      authorization = authorization
    )
    return(invisible(foreign_tracks_uris))
    
    
  }
  
  
}

check_args <- function(foreign_playlist_uri,
                       my_playlist_uri,
                       append,
                       user_id) {
  # Defensive checks for forking playlist function
  # check if both are character with length 1
  stopifnot(is.character(foreign_playlist_uri))
  stopifnot(is.character(my_playlist_uri) ||
              is.null(my_playlist_uri))
  
  stopifnot(length(foreign_playlist_uri) == 1)
  stopifnot((length(my_playlist_uri) == 1) ||
              is.null(my_playlist_uri))
  
  if (is.null(my_playlist_uri) && append) {
    stop("To append, my_playlist_uri must be specified")
  }
  
  if (!append && is.null(user_id) && is.null(my_playlist_uri)) {
    stop("user_id needed when creating new playlist (append = FALSE)")
  }
  
  
  
  
  # if my_playlist_uri null and append = TRUE, warning
  if (is.null(my_playlist_uri) && append) {
    warning("Append option selected but no playlist uri specified.
            Append option will be ignored")
  }
  
  
}



shuffle_pernamently <- function(playlist_id, authorization){
  # Shuffle the order of the songs on a playlist
  previous_tracks <- get_playlist_tracks(playlist_id = playlist_uri, 
                                         authorization = access_token$credentials$access_token)
  if (!inherits(previous_tracks, "data.frame")){
    stop("not a data.frame")
  }
  
  if(nrow(previous_tracks) ==0){
    warning("No songs in playlist")
    return(NULL)
  }
  
  previous_tracks <- previous_tracks$track.uri
  new_order <- sample(previous_tracks)
  
  truncate(playlist_uri, access_token)
  add_tracks_to_playlist(playlist_uri, new_order, authorization = access_token)
  
  invisible(previous_tracks)
}

