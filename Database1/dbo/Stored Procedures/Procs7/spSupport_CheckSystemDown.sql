CREATE PROCEDURE dbo.spSupport_CheckSystemDown
@SystemDown int OUTPUT
AS
Select @SystemDown = Count(*) 
  From Master.DBO.sysprocesses 
  Where program_name in (
    'MessageBus',
    'CalcEngine',
    'DatabaseMgr',
    'ClientMgr',
    'EventMgr',
    'Reader',
    'Writer',
    'SummaryMgr',
    'SPEngine',
    'Stubber',
    'DataGenerator'
     )
If @SystemDown > 0
  BEGIN 
    Select @SystemDown = 0 
    Print 'System running parm set, slow delete enabled.'
    Print 'Depending upon the amount of data, this procedure can run for a considerable amount of time.'
    Print 'This procedure should be run through SQL Server Agent if possible.'
  END
ELSE
  BEGIN
    Select @SystemDown = 1
    Print 'System down parm set, fast delete enabled.'
    Print 'WARNING: This procedure will DUMP the TRANSACTION LOG' 
    Print '         Please perform a backup before running this procedure.'
    Print 'Waiting 60 seconds before continuing.'
  END
-- These print statements force a spill of the output buffer when running from ISQL
PRINT '                                                                                                                                                                                                                                                               '
PRINT '                                                                                                                                                                                                                                                               '
PRINT '                                                                                                                                                                                                                                                               '
PRINT '                                                                                                                                                                                                                                                               '
PRINT '                                                                                                                                                                                                                                                               '
PRINT '                                                                                                                                                                                                                                                               '
PRINT '                                                                                                                                                                                                                                                               '
If @SystemDown = 1 
  BEGIN 
    WAITFOR DELAY '00:01:00'
    PRINT 'Process will now continue....' 
  END
