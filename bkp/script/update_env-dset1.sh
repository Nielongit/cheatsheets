#! /bin/bash
#
# Auther:	Kung-Ching Yeh
# date:		Dec 2014
# Function:	generate Chef environment file
# 2015/01/13:	move password DB file to /opt/app/passwd.db directory
#		change directory permssion to root.
# 2015/02/04:   print the environment output files at the end.
# 2015/04/23:   update comment/help page to clearify "-a" and password filename
#               add sed to overwrite severity for BHN-LSR
# 2015/05/04:	update to support multi instance/environments for the same app
#		change "-a" to "-e".
# 2015/05/15:	add environment json upload option.
# 2015/06/05:	Add cookbooks version validation and download if missing
#		add "-f" option for cookbook version file
# 2015/06/10:   Add "-F" force option to download/upload all cookbooks
# 2015/06/12:	change cookbook version from space or tab to "," delimiter.
# 2015/10/21:	line 222, mkdir cookbooks directory if missing
# 2015/11/20:	fix upload joson file prompt issue.
# 2015/11/23:	insert update_env.sh command and options to JSON file.
# 2016/01/20:   Add "-n" option for Chef node configuration
#               Add "LT" environment
#               add update_env.sh timestamp into environment josn file 
# 2016/01/21:	Add display host list to run "sudo run_chef-client.sh"
# 2016/02/22:	update to allow old Xen server for Chef deployment
# 2016/02/26:	add two new line at the end of cookbook and node config files
# 		cookbook section will skip blank lines.
# 2016/04/15:	restrict match pattern in function configure_chef_node
#		to avoid matching "expanded_run_list" block.
# 2016/04/21: 	kyeh	allow new DEV hostname pattern 'vdv'.
#

#################################
#
# initialize variables
#
#################################
declare -A patterns
declare -A instances
force=false
version_file=""
cmd_opts="$*"
opt_node="default"

function usage {
   echo "Usage:"
   echo "       $0 -e environment -i instance -t template -f git_version_file -F"
   echo "       -e, -i and -t arguments are required."
   echo ""
   echo "Exampe:"
   echo "   To generate instance specific JSON file:"
   echo "       $0 -e icp -i cte -t icpv5.2.1_environment_template.json"
   echo ""
   echo "   To generate environment specific JSON file:"
   echo "       $0 -e icp -i prod -t icpv5.2.1_environment_template.json"
   echo ""
   echo "   To validate, download/upload missing cookbooks and generate instance JSON file:"
   echo "       $0 -e icp -i cte -t icpv5.2.1_environment_template.json -f icp.3.0.1.txt"
   echo ""
   echo "   To download and upload ALL cookbooks and generate instance JSON file:"
   echo "       $0 -e soapapi-srm -i cte -t soapapi-srm-v0.0.1_environment_template.json -f chapi-1.0.5 -F"
   echo ""
   echo "Example to form the command line option:"
   echo ""
   echo "   From the release notes and find the following line:"
   echo ""
   echo "   git show HEAD:soapapi-srm/soapapi-srm-v0.0.1_environment_template.json"
   echo ""
   echo "    -e: soapapi-srm"
   echo "    -i: prod/cte"
   echo "    -t: soapapi-srm-v0.0.1_environment_template.json"
   echo "    -f: optional, file name for Git cookbooks version." 
   echo "    -F: optional, force download/upload cookbook in cookbook version file."
   echo "    -n: optional, Chef node configuration file."
   echo ""
   exit 1
}

##############################o $OPTARG | tr "[:upper:]" "[:lower:]")#
#
# command line options
#
################################
echo
echo
while getopts "e:i:t:f:hFn:" opt; do
  case $opt in
    e)
      opt_env=$( echo $OPTARG | tr "[:upper:]" "[:lower:]")
      echo "Environment:     ${opt_env}" 
      ;;
    i)
      opt_inst=$( echo $OPTARG | tr "[:upper:]" "[:lower:]")
      echo "Instance:        ${opt_inst}"
      ;;
    t)
      opt_template=$( echo $OPTARG | tr "[:upper:]" "[:lower:]")
      echo "Template:        ${opt_template}"
      ;;
    f)
      opt_version_file=$( echo $OPTARG | tr "[:upper:]" "[:lower:]")
      echo "Version file:    ${opt_version_file}"
      ;;
    F)
      opt_force=true
      echo "Force option: True"
      ;;
    n)
      opt_node_cfg=$(echo $OPTARG | tr "[:upper:]" "[:lower:]")
      echo "Node cfg file:   ${opt_node_cfg}"
      ;;
    h)
      usage
      ;;
  esac
done

################################
#
# check number of arguments.
#
################################
function check_cmd_option {
   echo 
   echo "======"
   echo "verify command line option..."
   if [[ -z "${opt_env}" || -z "${opt_inst}" || -z "${opt_template}" ]]; then
      echo ""
      echo "... missing argument."
      echo ""
      usage
   else
      echo "... looks good."
   fi
}

################################
#
# environmant DB password file location
#
################################
function validate_pattern_file {
   echo
   echo "======"
   echo "validate password pattern file..."
   envDir="/opt/app/passwd.db"
   patternFile="${envDir}/${opt_env}.db"
   if [ -e ${patternFile} ]; then
      echo "... environment pattern file found."
   else
      echo "... application environment not defined in ${envDir} directory."
      exit 255
   fi
}

################################
#
# figure out where to put instance files
#
################################
function get_chef_path {
   echo 
   echo "======"
   echo "figure out chef paths..."
   if [[ ${opt_inst} =~ "cte" ]]; then
      chef_path='chef/CTE'
      chef_org="CTE"
      #host_ptrn="omvctv"
      host_ptrn="rn"
   elif [[ ${opt_inst} =~ "prod" ]]; then
      chef_path='chef/PROD'
      chef_org="PROD"
      #host_ptrn="omvprv"
      host_ptrn="rn"
   elif [[ ${opt_inst} =~ "lt" ]]; then
      chef_path='chef/LT'
      chef_org="QA"
      #host_ptrn="omvltv"
      host_ptrn="om.ltv"
   elif [[ ${opt_inst} =~ "perf" ]]; then
      chef_path='chef/PERF'
      chef_org="QA"
      #host_ptrn="omvpfv"
      host_ptrn="rn"
   elif [[ ${opt_inst} =~ "qa" ]]; then
      chef_path='chef/QA'
      chef_org="QA"
      #host_ptrn="omvqav"
      host_ptrn="om.qav"
   elif [[ ${opt_inst} =~ "development" ]]; then
      chef_path='chef/DEVELOPMENT'
      chef_org="QA"
      #host_ptrn="omvdev"
      host_ptrn="saturn"
   else
      echo ""
      echo "ERROR: Environment instance must specify one of the follwoing"
      echo "  prod, cte, perf, qa or development (lowercase)"
      echo "exit now."
      exit 255
   fi

   chef_env_dir="${chef_path}/environments"
   chef_ckb_dir="${chef_path}/cookbooks"

   echo "... chef org:             ${chef_org}"
   echo "... chef path:            ${chef_path}"
   echo "... chef env path:        ${chef_env_dir}"
   echo "... chef cookbooks path:  ${chef_ckb_dir}"
}

#####################################
#
# FUNCTION: check cookbook directory
#
#####################################
function chk_cookbook_dir {
   echo
   echo "======"
   echo "check cookbooks directory..."
   if [ -d ~/${chef_ckb_dir}/${cookbook} ]; then
      if [ ${opt_force} ]; then
         echo "... applying FORCE option: ${cookbook} cookbook directory found and removed."
         rm -rf ~/${chef_ckb_dir}/${cookbook}
      else
         echo "... ${cookbook} cookbook exists, remove it? (y/n)"
         read response
         if [ "${response}" == "y" ]; then
            echo "   ... removing  ~/${chef_ckb_dir}/${cookbook}"
            rm -rf ~/${chef_ckb_dir}/${cookbook}
         else
            echo ""
            echo "... script terminated upon user request."
            echo ""
            exit 0
         fi
      fi
   elif [ ! -d ~/${chef_ckb_dir} ]; then
      echo "... ~/${chef_ckb_dir} doesn't exist.  creating it."
      mkdir -p ~/${chef_ckb_dir}
   else
      echo "... ~/${chef_ckb_dir} exist.  looks good."
   fi
}

#####################################
#
# FUNCTION: download cookbook
#
#####################################
function cookbook_download {
   echo
   echo "======"
   echo "download cookbook..."

   if [ -d ~/${chef_ckb_dir}/${cookbook} ]; then
      mkdir -p ~/${chef_ckb_dir}
   fi

   cd ~/${chef_ckb_dir}
#   git clone --branch ${version} https://${USER}@git.nexgen.neustar.biz/OMS-DSET-Cookbooks/${cookbook}.git	
   git clone --branch ${version} http://lindesh@saturn:8888/OMS-DSET-Cookbooks/${cookbook}.git
   # check error
   if [ $? -ne 0 ]; then
      echo 
      echo "ERROR, failed to download ${cookbook} v.${version}.  Exit now."
      echo 
      exit 255	  
   fi
   echo
}

#####################################
#
# FUNCTION: upload cookbook
#
#####################################
function cookbook_upload {
   echo ""
   echo "======"
   echo "upload cookbook..."

   cd ~/${chef_ckb_dir}
   if [ ${opt_force} ]; then
      echo "Applying FORCE option: upload ${cookbook} v.${version} to chef ${chef_org} organization..."
      knife cookbook upload ${cookbook} --freeze --force
   else
      echo "Upload ${cookbook} v.${version} to chef ${chef_org} organization..."
      knife cookbook upload ${cookbook} --freeze
   fi

   if [ $? -ne 0 ]; then
      echo 
      echo "ERROR: upload failed.  Stop now."
      echo 
      exit 255
   fi
   echo ""
}

################################
#
# check Git version and donwload if missing
#
################################
function validate_cookbook {
   echo
   echo "======"
   echo "validate cookbook version..."

   cd ~/${chef_env_dir}/${opt_env}
   # inject newline to the end of the file to fix Windows/GUI issue
   echo "" >> ~/${chef_env_dir}/${opt_env}/${opt_version_file}
   echo "" >> ~/${chef_env_dir}/${opt_env}/${opt_version_file}
   if [ -n "${opt_version_file}" ]; then
      if [ -e ${opt_version_file} ]; then
         CKBV="current-cookbook.version"
         echo "... download current cookbooks from ${chef_org} chef..."
         knife cookbook list -a > ${CKBV}
         IFS=","
         while read -u 3 line; do
            [ -z "${line}" ] && continue
            #line=$( echo ${line} | tr '\t' ' ' )
            token=(${line})
            cookbook=${token[0]}
            version=${token[1]}
            echo "... checking ${cookbook} v.${version}"
            found=$( grep "${cookbook}" ~/${chef_env_dir}/${opt_env}/${CKBV} | grep "${version}" )
            if [[ -n ${found} ]]; then
               echo "   ... FOUND."
               if [[ ${opt_force}  == "true" ]]; then
                  chk_cookbook_dir
                  cookbook_download
                  cookbook_upload
               fi
            else
               echo "   ... NOT FOUND."
               chk_cookbook_dir
               cookbook_download
               cookbook_upload
            fi
         done 3< ~/${chef_env_dir}/${opt_env}/${opt_version_file}

         echo ""
         echo "... cookbooks validation completed."
         echo ""
      else
         echo ""
         echo "ERROR: cookbook file ${version_file} not found.  Exit now."
         echo ""
         exit 255
      fi
   fi
}

################################
#
# check/create environments and environments.out directories
#
################################
function chk_environments_dir {
   echo
   echo "======"
   echo "check environments directory."
   if [ -d ~/${chef_env_dir} ]; then
      echo "... removing ~/${chef_env_dir} sub-directory."
      rm -rf ~/${chef_env_dir}
   fi

   echo "... check environment.out directory..."
   if [ ! -d ~/${chef_env_dir}.out ]; then
      echo "... creating ~/${chef_env_dir}.out directory"
      mkdir -p ~/${chef_env_dir}.out 
   fi

   if [ -d ~/${chef_env_dir}.out/${opt_env} ]; then
      echo "... removing files in ~/${opt_env} directory."
      rm -rf ~/${chef_env_dir}.out/${opt_env}/*
   fi
}

################################
#
# downlaod environments file
#
################################
function download_environments_file {
   echo
   echo "======"
   echo "download environments file."

   ################################
   #
   # Pull template from Git
   #
   ################################
   cd ~/${chef_path}
   echo "... cloning environments files."
#   git clone https://${USER}@git.nexgen.neustar.biz/OMS-DSET/environments.git
git clone http://lindesh@saturn:8888/NETECH/environments.git

   # check error
   if [ $? -ne 0 ]; then
      echo 
      echo "ERROR, failed to download ${cookbook} v.${version}.  Exit now."
      echo 
      exit 255
   fi
}

################################
#
# verify template name
#
################################
function verify_template_file {
   echo
   echo "======"
   echo "verify environments template file..."

   cd ~/${chef_env_dir}/${opt_env}
   if [ ! -e ${opt_template} ]; then
      echo "... ${opt_template} doesn't exit.  Please verify."
      echo 
      exit 255
   else
      echo "... ${opt_template} found."
   fi
}

################################
#
# build pattern hash table
#
################################
function build_pattern_hash {
   echo
   echo "======"
   echo "building pattern hash table..."

   IFS=","
   echo "... read in pattern file"
   while read line; do
      [[ $line =~ ^# ]] && continue
      [[ $line =~ ^$ ]] && continue
      if [[ $line =~ ${opt_inst} ]]; then
         token=($line)
         # build up instance list
         instances[${token[0]}]=1
         # build up pattern hash, no need after moved to Vault
         patterns[${token[1]}]=${token[2]}
      fi
   done < ${patternFile}

   ################################
   #
   # validate environment
   #
   ################################
   #echo "number of keys: ${#instances[@]}"
   if [ ${#instances[@]} -eq 0 ]; then
      echo "Instance not defined in pattern ${inst}.db file."
      echo "exit now."
      exit 255
   else
      echo "... pattern hash table built."
   fi
}

################################
#
# Generate instance environment file
#
################################
function generate_instance_json_file {
   echo
   echo "======"
   echo "genarate instance JSON file"
   env_out_dir="${chef_env_dir}.out/${opt_env}"

   # check if environments specicif dir exist
   if [ -d ~/${env_out_dir} ]; then
      echo "... ~/${env_out_dir} exist."
      echo "... removing files in the directory."
      rm -rf ~/${env_out_dir}/*
   else
      echo "... creating ${env_out_dir} directory."
      mkdir -p ~/${env_out_dir}
   fi
 
   # add two newlines to fix template EOF issue
   echo " " >> ~/${chef_env_dir}/${opt_env}/${opt_template}
   echo " " >> ~/${chef_env_dir}/${opt_env}/${opt_template}

   IFS=''
   for instance in "${!instances[@]}"; do
      echo "... generating $instance environment file..."
      cat /dev/null > ~/${env_out_dir}/${instance}.json
      while read line; do
         newline=$line
         #echo "reading... ${newline}"
         newline=${newline/<environment_file_name>/${instance}}
         # remove the following line once moved to Vault
         for key in ${!patterns[@]}; do
            newline=${newline/$key/${patterns[$key]}}
         done

         echo $newline >> ~/${env_out_dir}/${instance}.json.2

         # add updat_env.sh command line to JSON
         now=$(date +%Y.%m.%d-%H.%M.%Z)
         if [[ ${newline} =~ "default_attributes" ]]; then
            echo -e "\t" "\"update_env.sh\": \"${cmd_opts} -- ${now}\"," >> ~/${env_out_dir}/${instance}.json.2
         fi
      done < ~/${chef_env_dir}/${opt_env}/${opt_template}

      #################################
      #
      # overwrite severity to 3 for BHN log scan
      #
      #################################
      sed 's/alert_logger -s 2/alert_logger -s 3/g' < ~/${env_out_dir}/${instance}.json.2 > ~/${env_out_dir}/${instance}.json
      rm -f ~/$env_out_dir/${instance}.json.2

   done

   echo 
   echo "... instance specific file generated."
   echo 
   ls -l ~/${env_out_dir}
   echo 
   echo "... run: cd ~/${env_out_dir}"
   echo "... follow release note to upload environment files."
   echo 
}

################################
#
# option to upload environment files
#
################################
function upload_environment_json_file {
   echo
   echo "======"
   echo "upload environment JSON files..."
   echo
   echo "... upload environment files? (y/n)"
   read response
   cd ~/${env_out_dir}
   IFS=" "
   if [ "${response}" == "y" ]; then
      for file in $(ls -1 ~/${env_out_dir} | tr '\n' ' '); do
         echo "... uploading ~/${env_out_dir}/${file}"
            result=$(knife environment from file ~/${env_out_dir}/${file})
            echo ""
         if [[ $result =~ "Updated" ]]; then
            echo "   ... upload successfully"
         else
            echo "   ... upload FAILED"
         fi
         echo
      done
   else
      echo
      echo "... use the following command to upload JSON file manually."
      echo "... you need to be in correct Chef environment to execute the command."
      echo
      echo "    knife environment from file ~/${env_out_dir}/${file}"
      echo
      #echo "... exit now."
   fi
}

################################
#
# check Chef node configuration option and file
#
################################
function validate_node_cfg_option {
   if [ -n "${opt_node_cfg}" ]; then
   echo
   echo "====="
   echo "Validate node configuration file."
      echo "... node configuration option used."
      echo "... check Chef node configuration file: ${opt_node_cfg}"
      cd ~/${chef_env_dir}/${opt_env}
      if [ -e ${opt_node_cfg} ]; then
         echo "    ... node configuration file found."
         # add two new line at the end of node config file to fix Windows and GUI issue
         echo >> ${opt_node_cfg}
         echo >> ${opt_node_cfg}

         ################################
         #
         # proceed with node configuration
         #
         ################################
         configure_chef_node
      else
         echo "    ... node configuration file missing.  Exit now."
         exit 255
      fi
   fi
}

################################
#
# Chef node configuration
#
################################
function configure_chef_node {
   IFS=$' \n\t'
   json_out_dir="${chef_env_dir}.out/${opt_env}"

   echo
   echo "====="
   echo "Configure Chef node"
   host_dir="/opt/app/hosts"
   hostfile="${host_dir}/${opt_env}.host"
   host_count=$(grep -c "${host_ptrn}" ${hostfile})

   if [ ${host_count} == 0 ]; then
      echo "... No host defined in ${host_dir}/${opt_env}.host.  Pleaes verify."
      echo "... Exit now."
      exit 255
   fi

   for i in $(grep "${host_ptrn}" ${hostfile}); do
      IFS=""
      run_list="no"
      echo "... procesing ${i}..."
      [[ "${i}" =~ ^# ]] && continue
      [[ "${i}" =~ ^$ ]] && continue

      i=${i#*:}

      echo "    ... downloading ${i} node configuration"
      knife node show --format json -l ${i} > ${i}
      cat /dev/null > ${i}.json
      echo "    ... updating node configuration."

      ##############################
      #
      # replacing JOSN file with node cfg file
      #
      ##############################
      #IFS=""
      while read -u 4 -r line; do
         ##############################
         #
         # replacing run_list lines
         #
         ##############################
         #if [[ "${run_list}" == "yes" && "${line}" =~ "]," ]]; then
         if [[ "${run_list}" == "yes" ]]; then
            if [[ "${line}" =~ "role" ||   \
                  "${line}" =~ "recipe" || \
                  "${line}" =~ ^# ||       \
                  "${line}" =~ ^$  ]]; then
               continue
            else
               echo "    ... replacing run_list"
               while read -u 5 runlist; do
                  if [[ "${runlist}" =~ "run_list" ]]; then
                     runlist=${runlist#*:}
                     echo "      ${runlist}" >> ${i}.json
                     echo "       ... ${runlist}"
                  fi
               done 5< "${opt_node_cfg}"
               run_list="no"
            fi
         fi

         ##############################
         #
         # replacing chef_environment line
         #
         ##############################
         if [[ "${line}" =~ "chef_environment" ]]; then
            new_env=$(grep "chef_environment" ${opt_node_cfg} | awk '{print $2}')
            echo "    ... replacing chef_environment"
            echo "   \"chef_environment\": ${new_env}" >> ${i}.json
            echo "       ...      ${new_env}"
            echo
         elif [[ "${line}" =~ '"run_list"' ]]; then
            echo "   ${line}"  >> ${i}.json
            run_list="yes"
         else
            echo "${line}" >> ${i}.json
         fi

      done 4< "${i}"

      ##############################
      #
      # upload JOSN file
      #
      ##############################
      echo
      echo "    ... complete file update."
      echo "    ... uploading node configuration file."
      echo

      knife node from file ${i}.json
      #echo "knife node from file ${i}.json"
      echo

      # make a backup copy to environment.out dir
      cp ${i}* ~/${json_out_dir}/.
   done

   echo
   echo "A copy of updated node configuration can be found in"
   echo "   ~/${json_out_dir} directory"
   echo
}
  
################################
#
# Display host info for chef-cleint run
#
################################
function display_host_info {
   IFS=$' \n\t'
   host_dir="/opt/app/hosts"
   hostfile="${host_dir}/${opt_env}.host"

   echo
   echo "====="
   echo "... You need to execut 'sudo run_chef-client.sh'"
   echo "      on the following servers:"
   echo
   grep "${host_ptrn}" ${hostfile}
   echo
}

###########################
#
# main
#
###########################
check_cmd_option
validate_pattern_file
get_chef_path

chk_environments_dir
download_environments_file

verify_template_file
validate_cookbook

build_pattern_hash
generate_instance_json_file
upload_environment_json_file

###########################
#
# validate node configuariton need to run after upload_env_json_file
#
###########################
validate_node_cfg_option

display_host_info

