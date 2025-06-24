#!/usr/bin/env bash
red=$(tput setaf 197)
green=$(tput setaf 41)
x=$(tput sgr0)

# Snake properties
snake_body=( "." "_" "." "|" "⧖" "|" "⧖" "|" "⧖" "|" "\\" "|" "|" "8" ")" )
tongue="${red}~${x}"
snake=( "${snake_body[@]}" "${tongue}" )
snake_length=${#snake[@]}
#width=82
width=$COLUMNS
# Function to draw the snake
draw_snake() {
  for (( i=0; i<${#snake[@]}; i++ )); do
    printf "${green}%s${x}" "${snake[$i]}"
  done
}

# # Function to reverse the snake and change head/tail
# reverse_snake() {
#     # Swap head and tail
#     if [[ "${snake[0]}" == "." ]]; then
#         snake[0]="("
#         snake[-1]="."
#     else
#         snake[0]="."
#         snake[-1]="("
#     fi

#     # Reverse the snake body (excluding head and tail)
#     local mid_snake=( "${snake_body[@]:1:${#snake_body[@]}-1}" )
#     local reversed=()
#     for (( i=${#mid_snake[@]}-1; i>=0; i-- )); do
#         reversed+=( "${mid_snake[i]}" )
#     done
#     snake_body=( "${snake[0]}" "${reversed[@]}" "${snake[-1]}" )

#     # Add tongue to the front or back depending on direction
#     if [[ "${snake[0]}" == ")" ]]; then
#         snake=( "${snake_body[@]}" "${tongue}" )
#     else
#         snake=( "${tongue}" "${snake_body[@]}" )
#     fi
# }

# # Function to move the snake to the right
# move_right() {
#     snake[0]=">"  # Ensure the head is correct for moving right
#     snake[-1]=")"
#     snake=( "${snake_body[@]}" "${tongue}" )
#     for (( pos=0; pos<=width - snake_length - 1; pos++ )); do
#         echo -ne "\r\033[K"  # Return to the beginning of the line and clear it
#         printf "%*s" $pos ""  # Print spaces before the snake
#         draw_snake  # Draw the snake
#         sleep 0.1
#     done
# }

# Function to move the snake to the right and disappear
move_right() {
    for (( pos=0; pos<=width + snake_length; pos++ )); do
        width=$(( $COLUMNS - $snake_length))
        echo -ne "\r\033[K"  # Return to the beginning of the line and clear it
        printf "%*s" $pos ""  # Print spaces before the snake

        # Calculate how much of the snake to draw
        local draw_length=$snake_length
        if (( pos > width )); then
            draw_length=$((width + snake_length - pos))
        fi

        # Draw the snake up to draw_length
        for (( i=0; i<draw_length; i++ )); do
            printf "${green}%s${x}" "${snake[$i]}"
        done

        sleep 0.03
    done
}

# Function to move the snake to the left
move_left() {
    reverse_snake  # Reverse the snake before moving left
    for (( pos=width - snake_length - 1; pos>=0; pos-- )); do
        echo -ne "\r\033[K"  # Return to the beginning of the line and clear it
        printf "%*s" $pos ""  # Print spaces before the snake
        draw_snake  # Draw the snake
        sleep 0.1
    done
}

# Hide cursor
tput civis
# Ensure cursor is shown again when the script exits
trap 'tput cnorm' EXIT

# Main loop
# while true; do
#     move_right
#     move_left
# done

move_right
