# /bin/bash


STASH_SERVER_URL=localhost:7990
BITBUCKET_SERVER_URL=localhost:8083
SHEMA=http
PASSWORD_FILE_PATH=/home/aws/Documents/migration/.password-file
REPOS_PATH=REPOS_TEMP
USER=admin




echo -e "${On_IGreen} ${IPurple}Obteniendo los proyectos disponibles......"

readarray -t projects < <(curl -s -u $USER:$(cat $PASSWORD_FILE_PATH) $SHEMA://$STASH_SERVER_URL/rest/api/1.0/projects/ | jq -rc '.values | .[] | [{ key: .key, name: .name, description: .description }]')

projects_lenght=${#projects[@]}

if [ $projects_lenght -eq 0 ] 
then

	echo 'No hay proyectos disponibles......'

else

	echo 'Listando proyectos disponibles......'

	echo "${projects[@]}" | jq '.[] | .name'

	echo "Proyectos disponibles: ${projects_lenght}"

fi

rm -Rf $REPOS_PATH

mkdir $REPOS_PATH

cd $REPOS_PATH

for i in ${!projects[@]};
do

    key=$(echo "${projects[i]}" | jq '.[] | .key')

    name=$(echo "${projects[i]}" | jq '.[] | .name')

    description=$(echo "${projects[i]}" | jq '.[] | .description')

    body=$(echo -e "{\"key\":$key, \"name\":$name, \"description\":$description}")

    key_without_quotes=$(echo "$key" | tr -d '"')

    echo "Obteniendo repositorios del proyecto $name......"

    readarray -t repos < <(curl -s -u $USER:$(cat $PASSWORD_FILE_PATH) $SHEMA://$STASH_SERVER_URL/rest/api/1.0/projects/$key_without_quotes/repos | jq -rc '.values | .[] | [{ slug: .slug, name: .name }]')

	repos_lenght=${#repos[@]}

    if [ $repos_lenght -eq 0 ] 
    then

		echo 'No hay repositorios disponibles......'

	else

		echo 'Listando repositorios disponibles......'

		echo "${repos[@]}" | jq '.[] | .name'

		echo "Repositorios disponibles: ${repos_lenght}"

		echo 'Comprobando si ya existe el proyecto......'

		response=$(curl -s -u $USER:$(cat $PASSWORD_FILE_PATH) -H "Accept: application/json" "${SHEMA}://${BITBUCKET_SERVER_URL}/rest/api/1.0/projects/${key_without_quotes}" | jq '.errors?')
		
		if [ $response = null ]
		then

			echo 'El proyecto ya existe!......'

		else

			echo "Creando proyecto $name......"

			curl -s -u $USER:$(cat $PASSWORD_FILE_PATH) -X POST  -H "Content-Type: application/json; charset=UTF-8" -H "Accept: application/json" "${SHEMA}://${BITBUCKET_SERVER_URL}/rest/api/1.0/projects/" -d "${body}"

			echo 'Proyecto creado!......'

		fi

		for j in ${!repos[@]};
		do	

			slug=$(echo "${repos[j]}" | jq '.[] | .slug')

			slug_without_quotes=$(echo "$slug" | tr -d '"')

    		repo_name=$(echo "${repos[j]}" | jq '.[] | .name')

    		repo_body=$(echo -e "{\"slug\":$slug, \"name\":$repo_name}")

    		repos_response=$(curl -s -u $USER:$(cat $PASSWORD_FILE_PATH) -H "Accept: application/json" "${SHEMA}://${BITBUCKET_SERVER_URL}/rest/api/1.0/projects/${key_without_quotes}/repos/${slug_without_quotes}" | jq '.errors?')
		
			if [ $repos_response = null ]
			then

				echo 'El repositorio ya existe!......'

			else

				
				echo "Creando repositorio $repo_name......"

				curl -s -u $USER:$(cat $PASSWORD_FILE_PATH) -X POST  -H "Content-Type: application/json; charset=UTF-8" -H "Accept: application/json" "${SHEMA}://${BITBUCKET_SERVER_URL}/rest/api/1.0/projects/${key_without_quotes}/repos" -d "${repo_body}"

				echo 'Repositorio creado!......'

			fi

			echo "Clonando repositorio ${repo_name}"

			git clone --mirror $SHEMA://$USER:$(cat $PASSWORD_FILE_PATH)@$STASH_SERVER_URL/scm/$key_without_quotes/$slug_without_quotes.git

			cd $slug_without_quotes.git

			echo "Creando mirror del repositorio ${repo_name}"

			git push --mirror $SHEMA://$USER:$(cat $PASSWORD_FILE_PATH)@$BITBUCKET_SERVER_URL/scm/$key_without_quotes/$slug_without_quotes.git

			cd ..

		done;	

	fi
    
done;

echo 'DONE!!!!!!!!!!!!!'

exit 0;