/* Author database & user */
CREATE SCHEMA `{{ include "mgnl.mysql.author.database" . }}`;
CREATE USER `{{ include "mgnl.mysql.author.user" . }}`@`%` IDENTIFIED BY '{{ .Values.magnoliaAuthor.datasource.password }}';
GRANT ALL PRIVILEGES ON `{{ include "mgnl.mysql.author.database" . }}`.* TO `{{ include "mgnl.mysql.author.user" . }}`@`%`;

/* Public database & user */
CREATE SCHEMA `{{ include "mgnl.mysql.public.database" . }}`;
CREATE USER `{{ include "mgnl.mysql.public.user" . }}`@`%` IDENTIFIED BY '{{ .Values.magnoliaPublic.datasource.password }}';
GRANT ALL PRIVILEGES ON `{{ include "mgnl.mysql.public.database" . }}`.* TO `{{ include "mgnl.mysql.public.user" . }}`@`%`;