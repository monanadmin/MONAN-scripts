#module purge command doesn't working correctly
function unloadAllModules() {
 # it plays the role module purge
 module_listB="$(module list 2>&1 | cat | grep [1-9]*\) |cut -c5-| cut -d\/ -f1)"
 for module_name in $module_listB
 do
    module unload $module_name
 done
}

unloadAllModules
