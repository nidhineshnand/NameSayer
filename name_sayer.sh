#!/bin/bash

main_menu(){

  #Function used to print main menu
  printf "\n=========================================================================\n"
  printf "                       Welcome to NameSayer\n"
  printf "===========================================================================\n"

  printf "      Please select from the following options:\n\n"

  printf "      (l)ist existing creations\n"
  printf "      (p)lay an existing creations\n"
  printf "      (d)elete an existing creation\n"
  printf "      (c)reate a new creation\n"
  printf "      (q)uit authoring tool\n\n"


  read -p 'Enter a selection [l/p/d/c/q]: ' input

  #Case statements to check for input and what the user wants to do
  case $input in
    l)
    #Title for list
    printf "\nList of Files: \n"

    #This will list the set of creation by editing and reading off the file name in the creations folder
    list_files

    #Waiting for user input to show menu
    read -p $'\nPress enter to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #gGing to main_menu
      main_menu
    fi
    ;;

    p)
    #Playing the creation
    play_creation

    #Going to main_menu
    main_menu

    ;;

    d)
    #Calling function to delete files
    delete_creation

    #Waiting for user input to show menu
    read -p $'\nPress enter to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #Going to main_menu
      main_menu
    fi

    ;;

    #This case statement is used to create files
    c)
    #Calling function to make a creation
    make_creation

    #wWiting for user input to show menu
    read -p $'\nPress enter to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #going to main_menu
      main_menu
    fi

    ;;

    q)
    #Do nothing, breaks out of the statement and alerts the user that they're out of the program
    printf "\nQuiting NameSayer\n"
    printf "\nThank you for using NameSayer\n\n"

    ;;

    *)
    printf "\nThat was not a valid selection \n"
    main_menu

  esac
}


#Function used to create directories if there are none; otherwise the old directories are used
create_resources(){
  #making audio directory
  if [ ! -d "$resources/audios" ]; then
    mkdir -p "resources/audios"
  fi


  #making video directory
  if [ ! -d "$resources/videos" ]; then
    mkdir -p "resources/videos"
  fi


  #making direcotry for final output
  if [ ! -d "$resources/creations" ]; then
    mkdir -p "resources/creations"
  fi

}


#Function used to list files
list_files(){
  #Setting i increment value for listing files
  i=0;

  #Failing glob expands to nothing
  shopt -s nullglob

  #Printing files nicely with numbers
  for fname in resources/creations/*.mkv; do
    ((i++))
    echo $i. $(basename "$fname" .mkv) | tr '^' ' '

  done

  #Unseting non expanding behaviour
  shopt -u nullglob

  #If no creations are found then a message is printed
  if [ "$i" -eq 0 ]; then
    echo "==No creations found=="
  fi
}


#This function makes the creation which is the core part of NameSayer
make_creation(){

  #Prompting user to enter the file name of the creation
  read -p $'\nEnter the full name of your creation: ' newCreation

  #checking for duplication and if there is no duplication then file name is recieved
  nameOfFile=$(check_duplication "$newCreation")

  if [[ ! $nameOfFile ]];
  then
    #alerting user that the creation exists
    printf "\nCreation already exists \n"
    #Calling make creation to start the whole creation so that user can enter a non-duplicate file name
    make_creation

  else
    #Generating video with the given phrase
    generate_video "$newCreation" "$nameOfFile"

    #Putting in recording
    recording "$nameOfFile" "$newCreation"
  fi

  #Making the final creation
  final_creation "$nameOfFile"
}


#This function is used to check duplication of creations and returns their proper file name
#if the file does not exist
check_duplication(){

  #converting creations name to file name
  #adding ^
  filename=$( echo $1 | tr ' ' '^' )

  #Checking if file exists
  if [ ! -f "resources/creations/$filename.mkv" ]
  then
    #Returning filename if file does not exist
    echo $filename
  fi
}


#This function generates the video with the given phrase
generate_video(){
  #Assigning variables to input to increase legibility of code
  newCreation=$1
  nameOfFile=$2

  ffmpeg -f lavfi -i color=c=black:s=320x240:d=5 -vf \
  "drawtext=fontfile=/usr/share/fonts/truetype/ubuntu/Ubuntu-L.ttf:fontsize=30: \
  fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$newCreation'" \
  resources/videos/"$nameOfFile".mp4 -loglevel quiet
}


#This functions records the users voice when they are saying a certain phrase
recording(){
  #Setting a variable so that they're to understand
  nameOfFile=$1
  newCreation=$2

  #Asking user to record voice
  printf "\nTime to record your voice for your awesome 5 second creation"

  #prompting user to start recording
  read -p $'\nPress enter key to start recording\n' recordConfirmation

  #Checking if the any key was pressed
  if [[ recordConfirmation ]]; then
    #start recording
    printf "Recording for $newCreation"
  fi

  #This initiates the recording for 5 seconds
  ffmpeg -f alsa -ac 2 -i default -t 5 resources/audios/$nameOfFile.wav -loglevel quiet

  while true
  do

    #Asking user if they want to playback recording
    read -p $'\nDo you want to playback recording? (Enter [y] for yes or [n] for no) : ' playbackDecision

    #playing back recording when the user wants to
    if [ "$playbackDecision" == "y" ]; then
      #playing back recording
      printf "\nThis is your recording"

      #Playing recording
      timeout 5 ffplay resources/audios/$nameOfFile.wav -loglevel quiet
      break

    elif [ "$playbackDecision" == "n" ]; then
      #Breaking out of loop
      break

    else
      printf "\n Invalid input"
    fi
  done

  #Asking if the user wants to keep the recording or redo it
  while [ ! "$recordingDecision" = "k" ] || [ ! "$recordingDecision" = "r" ]
  do

    #Asking if they want to keep the recording
    read -p $'\nDo you want to keep this recording or redo? (Enter [k] for keep or [r] for redo): ' recordingDecision

    if [ "$recordingDecision" = "k" ]; #Decision to keep file
    then
      break
    elif [ "$recordingDecision" = "r" ];  #Decision to record again
    then
      #Deleting previous recording
      rm resources/audios/$nameOfFile.wav

      #Starting the recording function again
      recording "$nameOfFile" "$newCreation"

      break
    fi
  done

}


#This method makes the final creation
final_creation(){
  #Writing input to variables to make code more legible
  nameOfFile=$1

  #Combining the video and audio
  ffmpeg -i resources/videos/$nameOfFile.mp4 -i resources/audios/$nameOfFile.wav \
  -c:v copy -c:a aac -strict experimental resources/creations/$nameOfFile.mkv -loglevel quiet
}


#This function finds and plays the desired creation
play_creation(){
  #Listing files for the user
  list_files

  #If there are no creations
  if [ "$(list_files)" = "==No creations found==" ]; then

    #Waiting for user input to show menu
    read -p $'\nPress enter to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #Going to main_menu
      return
    fi
  fi

  read -p $'\nWhich creation would you like to play. Type name here: ' fileToPlay

  #Converting creations name to file name
  #Adding ^
  filename=$( echo $fileToPlay | tr ' ' '^' )
  #adding file extension
  Filename="$filename.mkv"

  #Checking if file exists
  if [ ! -f "resources/creations/$Filename" ];
  then

    #Alerting user that the wrong file name was typed.
    printf "\nSorry, this file was not found, \n"
    #Asking user to type again
    play_creation
    return
  fi

  #Playing file if it was found
  printf "\nPlaying creation $fileToPlay \n"
  timeout 5 ffplay resources/creations/$Filename -loglevel quiet

}


#This function finds and deletes the desired creation
delete_creation(){
  #Listing files for the user
  list_files

  #If there are no creations
  if [ "$(list_files)" = "==No creations found==" ]; then
    return
  fi

  read -p $'\nWhich creation would you like to delete from above. Type name here: ' fileToDelete

  #Converting creations name to file name
  #Adding ^
  filename=$( echo $fileToDelete | tr ' ' '^' )
  #adding file extension
  Filename="$filename.mkv"

  #Checking if file exists
  if [ ! -f "resources/creations/$Filename" ];
  then

    #Alerting user that the wrong file name was typed.
    printf "Sorry, this file was not found \n"

    #Asking user to type in the file they want to delete again again
    delete_creation
    return
  fi

  #Final check before deleting
  read -p $'\nAre you sure you want to delete this file!!!. Enter [y] for yes or any value for no: ' deleteAnswer

  #Checking if the user is sure about deleting the file
  if [ "$deleteAnswer" = "y" ]; then
    #Deleting creation and the files it was made with
    rm resources/creations/$Filename
    rm resources/audios/$filename.wav
    rm resources/videos/$filename.mp4

    #Telling user that the file was successfully deleted
    printf "\nFile was successfully deleted\n"
  else

    #Telling user that the file was not deleted
    printf "\nFile was not deleted\n"

  fi
}



#generating directories to store audio, video and final creation
create_resources

#printing main menu
main_menu
