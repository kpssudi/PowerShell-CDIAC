# This code sets up the HTML table in a more friendly format

$style = @'
<style type="text/css">
h1, h5, th { text-align: center; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 12px; padding: 5px 20px; color: #000;  text-align: right; font-weight: bold }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: yellow }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
'@


# This code defines the search string in the STO database table
$SQLServer = "OTDBS101\OTENTERPRISE1"
$SQLDBName = "CDIACDataEngDB"
$SQLQuery = "SELECT qu_task AS 'Task Name', qu_status AS 'Current Status', qu_start AS 'Queue Started', dbo.tmbatch.PB_FILENAME AS 'File Name', dbo.tmbatch.pb_pages AS 'Pages' 
               FROM [CDIACDataEngDB].[dbo].[queue]
                LEFT JOIN [CDIACDataEngDB].[dbo].[tmbatch] ON qu_batch = tmbatch.pb_batch
                    where (qu_status = 'pending' or qu_status = 'abort') and qu_task != 'VScanMulti'
                        ORDER BY qu_start;"

# This code connects to the SQL server and retrieves the data
$SQLConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security=SSPI;"

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection

$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd

$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

$SqlConnection.Close()

# This code outputs the retrieved data
$DataSet.Tables #| Format-Table -Auto


# This code emails a report regarding the results of the retrieved data
if($DataSet.Tables[0].Rows.Count -gt 0) {
$smtpServer = "smtpi1.treasurer.ca.gov"
$smtpFrom = "FileNet Notifications <itd-filenetsupport@treasurer.ca.gov>"
$smtpTo = "Usha.Patel@treasurer.ca.gov"
$smtpCc = "Michael.Cave@treasurer.ca.gov"
$messageSubject = "Summary Report: New CDIAC Data - Datacap Navigator Job Status"
$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
$message.Cc.Add($smtpCc)
$message.Bcc.Add("Kanhaiya.Sudi@treasurer.ca.gov")
$message.Subject = $messageSubject
$message.IsBodyHTML = $true
$message.Body = "<span style='background: #f75d59; color: white; max-width: 400px; padding: 5px 10px; font-weight: bold'>List of Pending and Aborted jobs.</span><br><br>"
#$message.Body += "<span style='background: #f75d59; color: white; max-width: 400px; padding: 5px 10px; font-weight: bold'>TOTAL DOCUMENTS UPLOADED: $totalUploaded</span> <br><br>"
$message.Body = $message.Body + ($DataSet.Tables[0] |select * -ExcludeProperty RowError, RowState, HasErrors, Name, Table, ItemArray | ConvertTo-Html -Head $style)

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($message)
}
