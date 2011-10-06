<VirtualHost *:$(set_apache_config_vhost.port)>

	# Main settings
	ServerName $(set_apache_config_vhost.fqdn)
	DocumentRoot $(set_apache_config_vhost.root)

	ServerAdmin webmaster@localhost

		# Modules settings

		# mod_expires

		ExpiresActive $(set_apache_config_vhost.finexpire)
		ExpiresDefault "$(set_apache_config_vhost.exp_ttl)"

		# mod_alias

		$(set_apache_config_vhost.finalias_one)
		$(set_apache_config_vhost.finalias_two)
		$(set_apache_config_vhost.finalias_three)

		# End modules settings

	# End main settings

	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>

	<Directory $(set_apache_config_vhost.root)>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory "/usr/lib/cgi-bin">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	ErrorLog /var/log/apache-$(set_apache_config_vhost.fqdn)-error.log
	CustomLog /var/log/apache-$(set_apache_config_vhost.fqdn)-access.log combined

</VirtualHost>
