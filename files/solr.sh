#!/usr/bin/env bash
#
#   Show Usage, Output to STDERR
#
function show_usage {
cat <<- _EOF_

Usage: solr add|remove|list -n name [-v version]
Options:
  -n name            : solr core name ie. sitename
  -v version         : solr version to use, default 3.6.2
                       3.4.0 for Magento EE 1.8.0.0 to 1.11.0.2
                       3.5.0 for Magento EE 1.12.0.x
                       3.6.2 for Magento EE 1.13+
_EOF_
exit 1
}

function show_header {
    echo -e "\e[32m"
    echo -e "*****************************"
    echo -e "* Solr script version 1.0.0 *"
    echo -e "*****************************\e[0m"
}

function confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case ${response} in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

function show_error {
    show_header
    echo -e "\e[31m${1}\e[0m"
}

function show_success {
    show_header
    echo -e "\e[32m${1}\e[0m"
}

function show_notice {
    echo -e "\e[33m${1}\e[0m"
}

function check_permissions {
    if [ "$(id -u)" != "0" ] ; then
        show_error "Command \e[1msolr add|remove \e[0;31mmust be run with 'sudo' or as root.  Aborting."
        exit 1
    fi
}

function check_solr_name {
    if [ "$solrName" = "" ] ; then
        show_error "Missing Solr core name!!"
		show_usage
    fi
}

function check_solr_version {
    allowed=("3.4.0" "3.5.0" "3.6.2")

    if [ "$solrVersion" == "" ] ; then
        solrVersion="3.6.2"
        show_notice "No Solr version provided, using Solr $solrVersion"
    fi

    if [[ ! " ${allowed[@]} " =~ " ${solrVersion} " ]]; then
        show_error "Invalid solr version: $solrVersion"
        show_usage
    fi
}

function list_solr_cores {
    IFS=$'\n'
	solrFiles=($(grep -Hs '<core name=' ${solrPath}solr-*/solr.xml))
	if [ "SolrFiles" == "" ] ; then
        show_error "No Solr cores found!!"
    fi

    if [ "$1" == "" ]; then
        show_header
    fi

    lastVersion=""
	for el in "${solrFiles[@]}" ; do
	    el=${el/$solrPath/}
	    el="${el//'/solr.xml'/}"
	    version=$(echo ${el} | cut -d ':' -f1)
	    core=$(echo ${el} | cut -d '"' -f2)
	    if [ "$lastVersion" == "$version" ]; then
		    echo "        - $core"
        else
            echo -e "  $version \n        - $core"
        fi
        lastVersion=${version}
	done
}

function add_solr_core {
    # Check if already exists
    IFS=$'\n'
	solrFiles=($(grep -Hs '<core name=' ${solrPath}solr-${solrVersion}/solr.xml))
	if [ "SolrFiles" != "" ] ; then
        for el in "${solrFiles[@]}" ; do
            core=$(echo ${el} | cut -d '"' -f2)
            if [ "$core" == "$solrName" ]; then
                show_error "Core with name $solrName already exists in Solr version $solrVersion\n"
                list_solr_cores false
                exit 1
            fi
        done
    fi

    # Validate solr.xml exists
    if [ ! -f "${solrPath}solr-${solrVersion}/solr.xml" ]; then
        show_error "Solr.xml in Solr version $solrVersion is missing!!"
        exit 1
    fi

    # Copy core-template
    cp -rf ${solrPath}solr-${solrVersion}/core-template ${solrPath}solr-${solrVersion}/${solrName}
    chown -R tomcat7:tomcat7 ${solrPath}

    # Add new core to solr.xml
    sed -i "s|  </cores>|    <core name=\"${solrName}\" instanceDir=\"${solrName}\" />\n  </cores>|" ${solrPath}solr-${solrVersion}/solr.xml

    # Restart Tomcat
    service tomcat7 restart

    # Confirmation message
    show_success "Successfully added Solr core $solrName to Solr version $solrVersion\n"
    show_notice "Add the following to your Magento Config to use this Solr core."
    show_notice "Solr Server Hostname:\e[0m 127.0.0.1"
    show_notice "Solr Server Port:\e[0m 8080"
    show_notice "Solr Server Username:\e[0m (blank)"
    show_notice "Solr Server Password:\e[0m (blank)"
    show_notice "Solr Server Path:\e[0m solr-$solrVersion/$solrName\n"
    list_solr_cores false
    exit 1
}

function remove_solr_core {
    # Check if already exists
    IFS=$'\n'
	solrFiles=($(grep -Hs '<core name=' ${solrPath}solr-${solrVersion}/solr.xml))
	exists=""
	if [ "SolrFiles" != "" ] ; then
        for el in "${solrFiles[@]}" ; do
            core=$(echo ${el} | cut -d '"' -f2)
            if [ "$core" == "$solrName" ]; then
                exists="true"
            fi
        done
    fi

    # Validate solr.xml exists
    if [ ! -f "${solrPath}solr-${solrVersion}/solr.xml" ]; then
        show_error "Solr.xml in Solr version $solrVersion is missing!!"
        exit 1
    fi

    # Show error if core not found
    if [ "$exists" == "" ]; then
        show_error "Core with name $solrName not found in Solr version $solrVersion\n"
        list_solr_cores false
        exit 1
    fi

    # Remove entry in solr.xml
    line_number=$(grep -n "name=\"$solrName\"" ${solrPath}solr-${solrVersion}/solr.xml | cut -d : -f 1  | tail -1)
    sed -i.bak -e "${line_number}d" ${solrPath}solr-${solrVersion}/solr.xml

    # Remove core folder
    rm -Rf ${solrPath}solr-${solrVersion}/$solrName

    # Restart Tomcat
    service tomcat7 restart

    # Confirmation Message
    show_success "Successfully removed Solr core $solrName from Solr version $solrVersion\n"
    list_solr_cores false
    exit 1
}

# Set Defaults
solrPath="/opt/solr/"

# Transform long options to short ones
for arg in "$@"; do
  case "$arg" in
    "add")
        shift
        set -- "$@" "-a"
        ;;
    "remove")
        shift
        set -- "$@" "-r"
        ;;
    "list")
        shift
        set -- "$@" "-l"
        ;;
     *)
        set -- "$@" "$arg"
  esac
done

# Parse flags
while getopts "h:n:v:alr" OPTION; do
    case $OPTION in
        h)
            show_usage
            ;;
        n)
            solrName=$OPTARG
            ;;
        v)
            solrVersion=$OPTARG
            ;;
        a)
            task='add'
            ;;
        r)
            task='remove'
            ;;
        l)
            task='list'
            ;;
        *)
            show_usage
            ;;
    esac
done

case ${task} in
    list)
        list_solr_cores
        ;;
    add)
        check_permissions
        check_solr_name
        check_solr_version
        add_solr_core
        ;;
    remove)
        check_permissions
        check_solr_name
        check_solr_version
        confirm "Remove Solr core $solrName? [y/N]" && remove_solr_core
        ;;
    *)
        show_header
        show_usage
        ;;
esac