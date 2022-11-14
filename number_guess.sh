#!/bin/bash

# assign psql command prompt
# PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"

# assign TARGET_VALUE a random number 1 - 1000
TARGET_VALUE=$(( RANDOM%1000 + 1 ))
echo $TARGET_VALUE

# prompt for username
echo "Enter your username:"
read USERNAME_IN

USER_DATA=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME_IN'")
# if user does not exist
if [[ -z $USER_DATA ]]
then 
  # insert user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME_IN')")
  # echo welcome to user
  echo "Welcome, $USERNAME_IN! It looks like this is your first time here."
# else (user exists)
else 
  # get stats (i.e. games_played, best_game)
  BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM users FULL JOIN games USING(user_Id) WHERE username='$USERNAME_IN';")
  BEST_GAME_FORMATTED=$(echo $BEST_GAME | sed -E 's/^ *| *$//g')
  echo $USER_DATA | while read USER_ID BAR USERNAME BAR GAMES_PLAYED
  do
    # echo stats
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME_FORMATTED guesses."
  done
fi

# assign a GUESSED bool variable as FALSE
GUESSED=0
# assign a COUNTER variable as 0;
COUNTER=0

# prompt for a guess
echo "Guess the secret number between 1 and 1000:"

# while not guessed (GUESSED == 0)
while [ $GUESSED -eq 0 ] 
do
  # increment COUNTER here if all tries count (regardless of validity)
  COUNTER=$(( $COUNTER + 1 ))
  # read user input into GUESSED_VALUE
  read GUESSED_VALUE
  # if GUESSED VALUE is not an integer (regex)
  if [[ ! $GUESSED_VALUE =~ ^[0-9]+$ ]]
  then 
    # notify user of invalid entry
    echo "That is not an integer, guess again:"
  else
  # if GUESSED_VALUE > TARGET_VALUE
    if [[ $GUESSED_VALUE -gt $TARGET_VALUE ]]
    then
      # notify user
      echo "It's lower than that, guess again:" 
      # increment COUNTER here if only valid tries count
    # else if GUESSED_VALUE < TARGET_VALUE
    elif [[ $GUESSED_VALUE -lt $TARGET_VALUE ]]
    then
      # notify user
      echo "It's higher than that, guess again:" 
      # increment COUNTER here if only valid tries count
    # else (GUESSED_VALUE == TARGET_VALUE)
    else
      # notify user of success and in how many tries
      echo "You guessed it in $COUNTER tries. The secret number was $TARGET_VALUE. Nice job!"
      # insert the game into the database    
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME_IN';");
      INSERT_GAME_RESULT=$($PSQL "INSERT INTO games (user_id, guesses) VALUES ($USER_ID, $COUNTER);")
      # update user's games played
      UPDATE_USER_GAMES_RESULT=$($PSQL "UPDATE users SET games_played = ((SELECT games_played FROM users WHERE user_id = $USER_ID) + 1) WHERE user_id = $USER_ID;")
      # done guessing
      GUESSED=1  
    fi # end if
  fi # end if
done # end while

# end game