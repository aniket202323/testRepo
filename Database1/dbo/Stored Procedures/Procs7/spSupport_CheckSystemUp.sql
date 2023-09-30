CREATE PROCEDURE dbo.spSupport_CheckSystemUp
AS
DECLARE @ServiceCount int
SET @ServiceCount = (SELECT Count(*) 
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
     ))
IF @ServiceCount > 0
  BEGIN
    PRINT 'Services are running.'
    RETURN 1
  END
ELSE
  BEGIN
    PRINT 'Services are not running.'
    RETURN 0
  END
