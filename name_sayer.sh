#!/bin/bash

main_menu(){

  #Function used to print main menu
  printf "\n===========================================================================\n"
  printf "Welcome to NameSayer\n"
  printf "===========================================================================\n"

  printf "      Please select from the following options:\n\n"

  printf "      (l)ist existing creations\n"
  printf "      (p)lay an existing creations\n"
  printf "      (d)elete an existing creation\n"
  printf "      (c)reate a new creation\n"
  printf "      (q)uit authoring tool\n\n"


  read -p 'Enter a selection [l/p/d/c/q]: ' input

  #case statements to check for input
  case $input in
    l)
    #this will list the set of creation by editing and reading off the file name in the creations folder
    list_files

    #waiting for user input to show menu
    read -p $'\nEnter any key to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #going to main_menu
      main_menu
    fi
    ;;

    p)
    #playing creation
    play_creation

    #waiting for user input to show menu
    read -p $'\nEnter any key to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #going to main_menu
      main_menu
    fi
    ;;

    d)
    #Calling function to delete files
    delete_creation

    #waiting for user input to show menu
    read -p $'\nEnter any key to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #going to main_menu
      main_menu
    fi

    ;;

    #this case statement is used to create files
    c)
    #Calling function to create file
    make_creation

    #waiting for user input to show menu
    read -p $'\nEnter any key to continue to the main menu\n' keyPress

    if [[ keyPress ]]; then
      #going to main_menu
      main_menu
    fi

    ;;

    q)
    #do nothing, breaks out of the statement
    printf "\nQuiting NameSayer\n\n"
    ;;

    *)
    printf "\nThat was not a valid selection \n"
    main_menu

  esac
}

#Function used to create directories if there are none otherwise the old directories are used
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


list_files(){
  #navigating to the right folder
  cd resources/creations

  i=0;

  #title for list
  printf "\nList of Files: \n"
  #printing files nicely
  ls | while read fname
  do
    ((i++))
    echo $i. ${fname%%.*} | tr '!@#_' ' '
  done

  #going back 2 directory levels
  cd ../..
}

#this function makes the creation
make_creation(){

  #prompting user to enter the file name of the creation
  read -p $'\nEnter the full name of your creation: ' newCreation

  #checking for duplication and if there is no duplication then file name is recieved
  nameOfFile=$(check_duplication "$newCreation")

  if [[ ! $nameOfFile ]];
  then
    #alerting user that the creation exists
    printf "\nCreation already exists \n"
    make_creation

  else

    #generating video with the given phrase
    generate_video "$newCreation" "$nameOfFile"

    #Putting in recording
    recording "$nameOfFile" "$newCreation"

  fi

  #Making the final creation
  final_creation "$nameOfFile"


}



#this function is used to check duplication of creations
check_duplication(){

  #converting creations name to file name
  #adding underscores
  filename=$( echo $1 | tr ' ' '!@#_' )

  #Checking if file exists and returning filename
  if [ ! -f "resources/creations/$filename.mkv" ]
  then
    echo $filename
  fi
}



#This function generates the video with the given phrase
generate_video(){


  ffmpeg -f lavfi -i color=c=black:s=320x240:d=5 -vf \
  "drawtext=fontfile=/Windows/Fonts/arial.ttf:fontsize=30: \
  fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$1'" \
  resources/videos/"$2".mp4 -loglevel quiet
}





#This functions records the users voice saying their name
recording(){

  #Setting a variable so that they're to understand
  nameOfFile=$1
  newCreation=$2

  printf "\n $1 this is the passed on file \n"
  #Asking user to record voice
  printf "\nTime to record your voice for your awesome 5 second creation"

  #prompting user to start recording
  read -p $'\nPress enter key to start recording\n' recordConfirmation

  #Checking if the any key was pressed
  if [[ recordConfirmation ]]; then
    #start recording
    printf "recording $2"
  fi

  #This records voice
  ffmpeg -f alsa -ac 2 -i default -t 5 resources/audios/$nameOfFile.wav -loglevel quiet


  #Asking user if they want to playback recording
  read -p $'\nDo you want to playback recording? (Enter [y] for yes or any other key for no) : ' playbackDecision

  #playing bak recording when the user wants to
  if [ "$playbackDecision" == "y" ]; then
    #playing back recording
    printf "\n This is your recording"
    timeout 5 ffplay resources/audios/$nameOfFile.wav -loglevel quiet
  fi

  #Asking if the user wants to keep the recording or redo it
  while true
  do

    #Asking if they want to keep the recording
    read -p $'\nDo you want to keep this recording or redo? (Enter [k] for keep or [r] for redo): ' recordingDecision

    if [ "$recordingDecision" = "k" ]
    then
      break
    fi

    if    [ $recordingDecision = "r" ]  #Decision to record again
    then

      #Deleting previous recording
      rm resources/audios/$nameOfFile.wav

      #Starting the recording function again
      recording "$nameOfFile" "$newCreation"

    fi
  done

}

#This method makes the final creation
final_creation(){
  #Combining the video and audio
  ffmpeg -i resources/videos/$1.mp4 -i resources/audios/$1.wav \
  -c:v copy -c:a aac -strict experimental resources/creations/$1.mkv -loglevel quiet
}


play_creation(){
  #Listing files for the user
  list_files

  read -p $'\nWhich creation would you like to play. Type name here:' fileToPlay

  #converting creations name to file name
  #adding underscores
  filename=$( echo $fileToPlay | tr ' ' '!@#_' )
  #adding file extension
  Filename="$filename.mkv"

  #Checking if file exists
  if [ ! -f "resources/creations/$Filename" ];
  then

    #Alerting user that the wrong file name was typed.
    printf "Sorry, this file was not found, \n"
    #Asking user to type again
    play_creation

  fi


  #playing file if it was found
  timeout 5 ffplay resources/creations/$Filename -loglevel quiet

}

delete_creation(){
  #Listing files for the user
  list_files

  read -p $'\n Which creation would you like to delete. Type name here: ' fileToDelete

  #converting creations name to file name
  #adding underscores
  filename=$( echo $fileToDelete | tr ' ' '!@#_' )
  #adding file extension
  Filename="$filename.mkv"

  #Checking if file exists
  if [ ! -f "resources/creations/$Filename" ];
  then

    #Alerting user that the wrong file name was typed.
    printf "Sorry, this file was not found \n"

    #Asking user to type again
    delete_creation
  fi

  read -p $'\nAre you sure you want to delete this file. Enter [y] for yes or any value for no: ' deleteAnswer


  if [ "$deleteAnswer" = "y" ]; then
    #deleting creation and the files it was made with
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



#generating directories
create_resources

#printing main menu
main_menu
