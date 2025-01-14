# GRAVITY SYNC BY VMSTAN #####################
# gs-ssh.sh ##################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Determine SSH Pathways
function create_sshcmd {
    timeout --preserve-status ${CMD_TIMEOUT} ${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "${CMD_REQUESTED}"
    error_validate
}

## Determine SSH Pathways
function create_rsynccmd {
    rsync --rsync-path="${RSYNC_REPATH}" -e "${SSH_CMD} -p ${SSH_PORT} -i $HOME/${SSH_PKIF}" ${RSYNC_SOURCE} ${RSYNC_TARGET} >/dev/null 2>&1
    error_validate
}

## Detect SSH-KEYGEN
function detect_sshkeygen {
    MESSAGE="Validating SSH-KEYGEN install"
    echo_stat
    
    if hash ssh-keygen >/dev/null 2>&1
    then
        echo_good
    else
        echo_fail
        MESSAGE="SSH-KEYGEN is required on $HOSTNAME"
        echo_info
        
        exit_nochange
    fi
}

function generate_sshkey {
    if [ -z $INPUT_REMOTE_PASS ]
    then
        if [ -f $HOME/${SSH_PKIF} ]
        then
            MESSAGE="Using existing ~/${SSH_PKIF} file"
            echo_info
        else
            if hash ssh-keygen >/dev/null 2>&1
            then
                MESSAGE="Generating ~/${SSH_PKIF} file"
                echo_stat
                
                ssh-keygen -q -P "" -t rsa -f $HOME/${SSH_PKIF} >/dev/null 2>&1
                error_validate
            else
                MESSAGE="No SSH-KEYGEN available"
                echo_warn
                exit_nochange
            fi
        fi
    fi
}

function export_sshkey {
    if [ -z $REMOTE_PASS ]
    then
        if [ -f $HOME/${SSH_PKIF} ]
        then
            MESSAGE="Registering key-pair to ${REMOTE_HOST}"
            echo_info
            
            ssh-copy-id -f -p ${SSH_PORT} -i $HOME/${SSH_PKIF}.pub ${REMOTE_USER}@${REMOTE_HOST}
        else
            MESSAGE="Error registering key-pair to ${REMOTE_HOST}"
            echo_warn
        fi
    fi
}

## Detect SSH & RSYNC
function detect_ssh {
    MESSAGE="${UI_VALIDATING} ${UI_CORE_OPENSSH}"
    echo_stat
    
    if hash ssh 2>/dev/null
    then
        echo_good
        SSH_CMD='ssh'
    elif hash dbclient 2>/dev/null
    then
        echo_fail
        
        MESSAGE="${UI_DROPBEAR_DEP}"
        echo_warn
        exit_nochange
    else
        echo_fail
        exit_nochange
    fi
    
    MESSAGE="${UI_VALIDATING} ${UI_CORE_RSYNC}"
    echo_stat
    
    if hash rsync 2>/dev/null
    then
        echo_good
    else
        echo_fail
        
        echo_warn
        exit_nochange
    fi
}

function detect_remotersync {
    MESSAGE="Creating test file on ${REMOTE_HOST}"
    echo_stat
    
    CMD_TIMEOUT='15'
    CMD_REQUESTED="touch ~/gs.test"
    create_sshcmd
    
    MESSAGE="If pull test fails ensure RSYNC is installed on ${REMOTE_HOST}"
    echo_warn
    
    MESSAGE="Pulling test file to $HOSTNAME"
    echo_stat
    
    RSYNC_REPATH="rsync"
    RSYNC_SOURCE="${REMOTE_USER}@${REMOTE_HOST}:~/gs.test"
    RSYNC_TARGET="${LOCAL_FOLDR}/gs.test"
    create_rsynccmd
    
    MESSAGE="Cleaning up local test file"
    echo_stat
    
    rm ${LOCAL_FOLDR}/gs.test
    error_validate
    
    MESSAGE="Cleaning up remote test file"
    echo_stat
    
    CMD_TIMEOUT='15'
    CMD_REQUESTED="rm ~/gs.test"
    create_sshcmd
}

function show_target {
    MESSAGE="${UI_CORE_UC_PRIMARY} ${UI_CORE_APP}: ${REMOTE_USER}@${REMOTE_HOST}"
    echo_info
    
    detect_ssh
}