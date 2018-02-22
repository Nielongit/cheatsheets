#!/bin/bash
file="soaadp-development-primary.json"
env_out_dir="chef/DEVELOPMENT/environments.out/soaadp/"

echo "... uploading ${file}"
            result=$(knife environment from file ~/${env_out_dir}/${file})
            echo "i**$?** $result"
         if [[ $result =~ "Updated" ]]; then
            echo "   ... upload successfully"
         else
            echo "   ... upload FAILED"
         fi
         echo
