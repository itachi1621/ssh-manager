#!/bin/bash
#This script allows the user to save ssh logins and then connect to the server
#by just entering the number of the server
#I created this script because remembering all the ssh logins is a pain in the @$$
#Also i didn't want to use a programming language like python or ruby,
#because I wanted to keep it simple and avoid installing any dependencies
#I also wanted to learn more about bash scripting with awk and sed
# -- Scott Gopaulchan 2023

warning="\033[1;31m" #Red
success="\033[1;32m" #Green
info="\033[1;33m" #Yellow
reset="\033[0m" #Reset color
cfg_file_name="$HOME/.ssh_manager_config" #The file where the server details are stored

#Check if the config file exists if not create it
if [ ! -f "$cfg_file_name" ]
then
    touch "$cfg_file_name"
fi

fileEmptyCheck(){
    if [ ! -s "$cfg_file_name" ] # -s checks if the file is empty
    then
        printf "%s${warning}No servers added yet${reset}\n"
        menu
    fi
}

addNewServer(){


read -p "Enter the server name/alias: " name

#Check if the server name is blank
if [ -z "$name" ] # -z checks if the string is empty
then
    printf "%s${warning}Server name cannot be blank${reset}\n"
    addNewServer
fi


}

addNewServerIp(){

read -p "Enter the server IP or domain name: " ip

#Check if  ip is blank and conforms to the regex pattern for ip address or domain name i.e xxx.xxx.xxx.xxx or example.com
if [ -z "$ip" ] || ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && ! [[ "$ip" =~ ^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$ ]]
#Yeah no idea what this regex does looks like gibberish to me, I used it from stackoverflow and confimed it works using regex101.com
then
    printf "%s${warning}Invalid IP or domain name${reset}\n"
    addNewServerIp
fi

}

addNewServerPort(){


read -p "Enter the port number leave blank for default of 22 : " port

#check if the port is blank
if [ -z "$port" ]
then
    port=22
fi

#Check if the port is a number and is between 1 and 65535 (Valid Port ranges)
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -gt 65535 ] || [ "$port" -lt 1 ]
then
    printf "%s${warning}Invalid port number${reset}\n"
    addNewServerPort
fi



}

addNewServerUser(){


read -p "Enter the username: " user

#Check if the user is blank
if [ -z "$user" ] # -z checks if the string is empty
then
    printf "%s${warning}Username cannot be blank${reset}\n"
    addNewServerUser
fi



 }

 createNewSSHCredentials(){

    printf "%s${info}===========================${reset}\n"
    echo -e "${info}Add New SSH Server${reset}"
    printf "%s${info}===========================${reset}\n"

    addNewServer
    addNewServerIp
    addNewServerPort
    addNewServerUser


    echo "$name,$ip,$port,$user" >> "$cfg_file_name"

    echo -e "${success}Server added successfully${reset}"
    read -p "Do you want to connect to the server now? (y/n) " selection -n 1 -r
    if [[ $selection =~ ^[Yy]$ ]]
    then
        connectToSSHServer "qc"
    fi

    menu

 }

 listSSHCredentials(){
    fileEmptyCheck
    printf "%s${info}===========================${reset}\n"
    echo -e "${info}Listing all servers${reset}"
    printf "%s${info}===========================${reset}\n"
    #Now to use awk to list the servers in a nice format 1 , 2 , 3 etc in a table format starting with the header but starting the numbering at from the second line
    printf "%s${info}#  Name IP/Host Port Username${reset}\n"
    awk -F, '{print NR " " $1 " " $2 " " $3 " " $4}' "$cfg_file_name" | column -t # -t is used to align the columns,  using awk is always awkward .... but it works

    menu



 }

 connectToSSHServer(){

    if [ "$1" == "qc" ] #qc is the quick connect option
    then
        fileEmptyCheck
        serverName=$name
        serverIp=$ip
        serverPort=$port
        serverUser=$user
    else

    fileEmptyCheck
    printf "%s${info}===========================${reset}\n"
     echo -e "${info}Listing all servers${reset}"
     printf "%s${info}===========================${reset}\n"
    #Now to use awk to list the servers in a nice format 1 , 2 , 3 etc
    printf "%s${info}#  Name \t IP/Host \tPort Username${reset}\n"
    awk -F, '{print NR " " $1 " " $2 " " $3 " " $4}' "$cfg_file_name" | column -t # -t is used to align the columns,  using awk is always awkward .... but it works

    printf "%s${info}Enter the number of the server you want to connect to or enter 0 to cancel : ${reset}"
    read -p "" serverNumber

    if [ "$serverNumber" == 0 ]
    then
        menu
    fi
    # Now we  have to check if the server number is blank
    # or not a number or valid using regex (I HATE REGEX )
    #and the wc command to count the number of lines in the file
    if [ -z "$serverNumber" ] || ! [[ "$serverNumber" =~ ^[0-9]+$ ]] || [ "$serverNumber" -gt "$(wc -l < "$cfg_file_name")" ] || [ "$serverNumber" -lt 1 ]
    then
        printf "%s${warning}Invalid server number${reset}\n"
        connectToSSHServer # You have to love reursive functions
    fi

        #Now to use awk to filter the server number and get the details

        # Alright so this part is where it get bannans  and confusing
        # -F, is used to specify the field separator which in this case is a comma
        # -v is used to pass a variable to awk,
        # NR is the current line number,
        #serverNumber is the variable passed to awk
        # and the last part is the action to perform on the current line
        # so if the current line number is equal to the server number then print the column n which we are storing in the variable
        #and the last part is the file to read from
    serverName=$(awk -F, -v serverNumber="$serverNumber" 'NR==serverNumber {print $1}' "$cfg_file_name")
    serverIp=$(awk -F, -v serverNumber="$serverNumber" 'NR==serverNumber {print $2}' "$cfg_file_name")
    serverPort=$(awk -F, -v serverNumber="$serverNumber" 'NR==serverNumber {print $3}' "$cfg_file_name")
    serverUser=$(awk -F, -v serverNumber="$serverNumber" 'NR==serverNumber {print $4}' "$cfg_file_name")


fi
    #echo $serverPort
    #Here we go connecting to the server
    printf "%s${success}Connecting to ${serverName} ...${reset}\n"
    ssh -p "$serverPort" "$serverUser""@""$serverIp"

    menu



 }

 deleteSSHServer(){

    fileEmptyCheck
    printf "%s${info}===========================${reset}\n"
    echo -e "${info}Listing all servers${reset}"
    printf "%s${info}===========================${reset}\n"
    #Now to use awk to list the servers in a nice format 1 , 2 , 3 etc
    printf "%s${info}#  Name IP/Host \tPort Username${reset}\n"
    awk -F, '{print NR " " $1 " " $2 " " $3 " " $4}' "$cfg_file_name" | column -t # -t is used to align the columns,  using awk is always awkward .... but it works

    printf "%s${warning}Enter the number of the server you want to delete or enter 0 to cancel : ${reset}"
    read -p "" serverNumber

    #Check if the user wants to cancel
    if [ "$serverNumber" -eq 0 ]
    then
        menu
    fi
    # Now we  have to check if the server number is blank
    # or not a number or valid using regex (I HATE REGEX )
    #and the wc command to count the number of lines in the file
    if [ -z "$serverNumber" ] || ! [[ "$serverNumber" =~ ^[0-9]+$ ]] || [ "$serverNumber" -gt "$(wc -l < "$cfg_file_name")" ] || [ "$serverNumber" -lt 1 ]
    then
        printf "%s${warning}Invalid server number${reset}\n"
        deleteSSHServer # You have to love reursive functions
    fi

    #Now to delete the server from the file using sed and the info from awk then save the file
    # -i is used to edit the file in place
    # -e is used to specify the command to run
    # '' is used to specify the line number
    # serverNumber is the variable passed to sed
    # d is used to delete the line
    # and the last part is the pattern to match
    # so in this case we are matching the line number and deleting it
    #Hopefully my comments are clear enough to whoever is reading this

    sed -i -e ''"$serverNumber"'d' "$cfg_file_name"

    printf "%s${success}Server deleted successfully${reset}\n\n"

    listSSHCredentials


 }

 menu(){

    printf "%s${info}===========================${reset}\n"
    printf "%s${success}SSH Server Manager${reset}\n"
    printf "%s${info}===========================${reset}\n"
    printf "1. Add new server \n"
    printf "2. Connect to a saved SSH server\n"
    printf "3. List servers\n"
    printf "%s${warning}4. Delete a server${reset}\n"
    printf "5. Exit\n"
    printf "Enter your choice : "
    read -p "" choice

    case $choice in
        1) createNewSSHCredentials;;
        2) connectToSSHServer;;
        3) listSSHCredentials;;
        4) deleteSSHServer;;
        5) exit;;
        *) printf "%s${warning}Invalid choice${reset}\n"; menu;;
    esac

 }



menu
