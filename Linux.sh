#!/bin/bash

CREDENTIALS="credentials.txt"
CREATED_USERS="created_users.txt"
QUIZ_LOG="tutorial_scores.log"

mkdir -p /tmp/linux_tutor
touch "$CREDENTIALS" "$CREATED_USERS" "$QUIZ_LOG"
chmod 600 "$CREDENTIALS"

if [[ $EUID -ne 0 ]]; then
  dialog --msgbox "Please run as root!" 6 40
  clear; exit 1
fi

# === Authentication ===
signup() {
  while true; do
    U=$(dialog --inputbox "Choose username:" 10 40 3>&1 1>&2 2>&3) || return
    [[ -z "$U" ]] && return
    grep -q "^$U:" "$CREDENTIALS" && { dialog --msgbox "Username exists!" 5 40; return; }

    P=$(dialog --passwordbox "Choose password:" 10 40 3>&1 1>&2 2>&3) || return
    [[ -z "$P" ]] && return

    H=$(echo "$P" | sha256sum | awk '{print $1}')
    echo "$U:$H" >> "$CREDENTIALS"
    useradd "$U"
    echo "$U:$P" | chpasswd
    echo "$U:$P" >> "$CREATED_USERS"
    dialog --msgbox "User $U created." 6 40
    break
  done
}

signin() {
  while true; do
    U=$(dialog --inputbox "Username:" 10 40 3>&1 1>&2 2>&3) || return 1
    [[ -z "$U" ]] && return 1

    P=$(dialog --passwordbox "Password:" 10 40 3>&1 1>&2 2>&3) || return 1
    [[ -z "$P" ]] && return 1

    H=$(echo "$P" | sha256sum | awk '{print $1}')
    grep -q "^$U:$H$" "$CREDENTIALS" || { dialog --msgbox "Invalid credentials!" 6 40; return 1; }

    dialog --msgbox "Welcome $U!" 6 30
    break
  done
}

# === User Management ===
add_user() {
  U=$(dialog --inputbox "New username:" 10 40 3>&1 1>&2 2>&3) || return
  [[ -z "$U" ]] && return
  grep -q "^$U:" "$CREATED_USERS" && { dialog --msgbox "User exists!" 6 30; return; }

  P=$(dialog --passwordbox "Password:" 10 40 3>&1 1>&2 2>&3) || return
  [[ -z "$P" ]] && return

  useradd "$U"
  echo "$U:$P" | chpasswd
  echo "$U:$P" >> "$CREATED_USERS"
  H=$(echo "$P" | sha256sum | awk '{print $1}')
  echo "$U:$H" >> "$CREDENTIALS"
  dialog --msgbox "User $U added." 6 30
}

delete_user() {
  U=$(dialog --inputbox "Username to delete:" 10 40 3>&1 1>&2 2>&3) || return
  [[ -z "$U" ]] && return
  grep -q "^$U:" "$CREATED_USERS" || { dialog --msgbox "Only created users can be deleted!" 6 40; return; }

  userdel "$U"
  sed -i "/^$U:/d" "$CREATED_USERS" "$CREDENTIALS"
  sed -i "/^$U,/d" "$QUIZ_LOG"
  dialog --msgbox "User $U and their scores deleted." 6 40
}

modify_user() {
  U=$(dialog --inputbox "Username to modify:" 10 40 3>&1 1>&2 2>&3) || return
  [[ -z "$U" ]] && return
  grep -q "^$U:" "$CREATED_USERS" || { dialog --msgbox "Only created users can be modified!" 6 40; return; }

  P=$(dialog --passwordbox "New password:" 10 40 3>&1 1>&2 2>&3) || return
  [[ -z "$P" ]] && return

  echo "$U:$P" | chpasswd
  sed -i "/^$U:/d" "$CREATED_USERS"
  echo "$U:$P" >> "$CREATED_USERS"
  H=$(echo "$P" | sha256sum | awk '{print $1}')
  sed -i "/^$U:/d" "$CREDENTIALS"
  echo "$U:$H" >> "$CREDENTIALS"
  dialog --msgbox "Password updated for $U." 6 30
}

list_users() {
  cut -d: -f1 "$CREATED_USERS" > /tmp/linux_tutor/users.txt
  dialog --textbox /tmp/linux_tutor/users.txt 20 50
}

# === Quiz ===
start_quiz() {
  # Ask for login again before quiz
  dialog --msgbox "Login to start quiz:" 6 40
  signin || return
  USER="$U"

  declare -A QUIZ
  QUIZ["Which command lists files?"]="ls"
  QUIZ["Which command removes files?"]="rm"
  QUIZ["Which command shows current directory?"]="pwd"
  QUIZ["Which command creates a directory?"]="mkdir"
  QUIZ["Which command shows running processes?"]="ps"
  QUIZ["Which command moves files?"]="mv"
  QUIZ["Which command displays first lines?"]="head"
  QUIZ["Which command searches text?"]="grep"
  QUIZ["Which command changes permissions?"]="chmod"
  QUIZ["Which command shows disk usage?"]="df"

  SCORE=0
  START=$(date +%s)
  mapfile -t QUESTIONS < <(printf "%s\n" "${!QUIZ[@]}" | shuf | head -10)

  for i in "${!QUESTIONS[@]}"; do
    Q="${QUESTIONS[$i]}"
    CORRECT="${QUIZ[$Q]}"
    ANSWER=$(dialog --inputbox "Q$((i+1)): $Q" 8 50 3>&1 1>&2 2>&3)
    [[ "${ANSWER,,}" == "${CORRECT,,}" ]] && ((SCORE++))
    dialog --msgbox "You answered: $ANSWER\nCorrect: $CORRECT\nScore: $SCORE / $((i+1))" 8 50
  done

  END=$(date +%s)
  TIME=$((END - START))
  echo "$USER,$SCORE,$TIME" >> "$QUIZ_LOG"

  dialog --msgbox "🎓 Quiz Completed!\nUser: $USER\nScore: $SCORE/10\nTime: ${TIME}s" 10 50
}

view_scores() {
  sort -t, -k2,2nr -k3,3n "$QUIZ_LOG" | head -10 > /tmp/linux_tutor/top.txt
  dialog --textbox /tmp/linux_tutor/top.txt 20 50
}

# === Menus ===
main_menu() {
  while true; do
    CH=$(dialog --title "Main Menu" --menu "Select:" 15 50 7 \
      1 "Add User" \
      2 "Delete User" \
      3 "Modify User" \
      4 "List Users" \
      5 "Start Tutorial Quiz" \
      6 "View Top Scores" \
      7 "Exit" \
      3>&1 1>&2 2>&3)
    case $CH in
      1) add_user ;;
      2) delete_user ;;
      3) modify_user ;;
      4) list_users ;;
      5) start_quiz ;;
      6) view_scores ;;
      7) clear; exit 0 ;;
    esac
  done
}

login_menu() {
  while true; do
    CH=$(dialog --title "Login" --menu "Choose:" 10 40 3 \
      1 "Sign Up" \
      2 "Sign In and Continue" \
      3 "Exit" \
      3>&1 1>&2 2>&3)
    case $CH in
      1) signup ;;
      2) signin && break ;;
      3) clear; exit 0 ;;
    esac
  done
}

# === Start ===

