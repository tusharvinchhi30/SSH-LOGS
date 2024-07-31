#!/bin/bash
#
#
# Source the configuration file
source config.sh

# Create the logs directory if it does not exist
mkdir -p logs

# Function to prompt for user input
prompt_user() {
    clear
    echo "Please choose an action:"
    echo "Press 1 for Grep"
    echo "Press 2 for Tail"
    read -p "Enter your choice (1 or 2): " ACTION

    while [[ "$ACTION" != "1" && "$ACTION" != "2" ]]; do
        clear
        echo "Invalid input. Please enter '1' or '2'."
        echo "Press 1 for Grep"
        echo "Press 2 for Tail"
        read -p "Enter your choice (1 or 2): " ACTION
    done

    if [[ "$ACTION" == "1" ]]; then
        clear
        read -p "Enter the Transaction ID: " TRANSACTION_ID
    fi
}

# Function to prompt for file selection when tailing
prompt_file_selection() {
    clear
    echo "Please choose the file to tail:"
    
    # Loop through file descriptions to display choices
    for i in "${!FILES[@]}"; do
        echo "$((i + 1)). ${FILE_DESCRIPTIONS[i]}"
    done
    
    read -p "Enter your choice (1, 2, 3, etc.): " FILE_CHOICE

    while [[ "$FILE_CHOICE" -lt 1 || "$FILE_CHOICE" -gt "${#FILES[@]}" ]]; do
        clear
        echo "Invalid input. Please enter a number from 1 to ${#FILES[@]}."
        echo "Please choose the file to tail:"
        for i in "${!FILES[@]}"; do
            echo "$((i + 1)). ${FILE_DESCRIPTIONS[i]}"
        done
        read -p "Enter your choice (1, 2, 3, etc.): " FILE_CHOICE
    done

    # Set the tail file based on user choice
    TAIL_FILE="${FILES[$((FILE_CHOICE - 1))]}"
}

# Function to ask if user wants to grep and get the Transaction ID if yes
prompt_grep_option() {
    clear
    read -p "Do you want to grep the output? (y/n): " GREP_OPTION

    if [[ "$GREP_OPTION" == "y" || "$GREP_OPTION" == "Y" ]]; then
        read -p "Enter the Transaction ID: " TRANSACTION_ID
        GREP_COMMAND=" | grep '$TRANSACTION_ID'"
    else
        GREP_COMMAND=""
    fi
}

# Function to construct SSH command for grep action
construct_grep_command() {
    SSH_COMMAND="cd /data/ATC/MobifinEliteServices/LogEvent/logs/ &&"

    for FILE in "${FILES[@]}"; do
        SSH_COMMAND+=" echo 'Results from $FILE for Transaction ID $TRANSACTION_ID:' && 
                      (cat $FILE | grep '$TRANSACTION_ID' || echo 'No matches found in $FILE') && 
                      echo -e '\n\n\n' &&"
    done

    # Remove the last '&&' and add a final newline
    SSH_COMMAND="${SSH_COMMAND%&&}"
}

# Prompt the user for action and transaction ID
prompt_user

# Define the SSH command and log file name based on user input
case $ACTION in
    1)
        echo "Getting Logs for ${TRANSACTION_ID}....."
        OUTPUT_FILE="logs/grep-${TRANSACTION_ID}.log"
        construct_grep_command
        
        # Execute the SSH command and handle empty outputs
        ssh $USER@$SERVER "$SSH_COMMAND" > "$OUTPUT_FILE" 2>&1
        ;;
    2)
        prompt_file_selection
        prompt_grep_option
        echo "Getting Logs from ${TAIL_FILE}....."
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        OUTPUT_FILE="logs/Tail-${TAIL_FILE}-${TRANSACTION_ID}-${TIMESTAMP}.log"
        SSH_COMMAND="cd /data/ATC/MobifinEliteServices/LogEvent/logs/ && timeout $TAIL_TIMEOUT tail -f $TAIL_FILE${GREP_COMMAND}"
        
        # Execute the SSH command and handle empty outputs
        ssh $USER@$SERVER "$SSH_COMMAND" > "$OUTPUT_FILE" 2>&1
        ;;
esac

echo "Script completed."
echo "Logs Generated at :- ${OUTPUT_FILE}"
sleep 10
