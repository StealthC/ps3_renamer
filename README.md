ps3_renamer
===========

Searches through a specified folder for PS3 games and renames the folder to a understandable pattern.


USAGE: 
  `ruby ps3_renamer.rb folder rename_pattern`
  
  **folder**    - Directory that contains PS3 GAMES, if not especified, the scripts runs in current directory
  
  **rename_pattern**   - The renaming pattern, it must be in "Ruby Style", the default is `"%{TITLE} - %{TITLE_ID}"` where:
  
                  TITLE     = Title of the game, example: "Dead or Alive 5"
                  TITLE_ID  = ID of disc, example: "BLUS1234"
                  
  OBS: Spaces and special characters are escaped with "_"
