CREATE PROCEDURE dbo.spServer_CmnSendTableModified
@TableType int
AS
declare @hr as int
declare @obj as int
declare @userid as int
declare @ip as varchar (50)
declare @port as int
-- Create the gateway COM object
exec @hr =sp_OACreate 'PRMessages.PRGateway', @obj OUTPUT
if @hr <> 0
begin
  RAISERROR('Error creating Gateway object',0,1)
  return (1)
end
-- Setup and connect to Gateway
exec @hr =sp_OASetProperty @obj, 'AppName', 'SQLServer'
select @userid=27
select @ip=listener_address, @port=listener_port from cxs_service   Where Service_Id = 14
exec @hr =sp_OAMethod @obj, 'Startup', NULL, @IP, @port, 'RealTimePassword2000',  @userid
if @hr <> 0
begin
  RAISERROR('Error connecting to Gateway',0,1)
  return (1)
end
-- Send the message
exec @hr =sp_OAMethod @obj, 'SendTableModified', NULL, @TableType
if @hr <> 0
begin
  RAISERROR('Error sending table modification message',0,1)
  return (1)
end
-- Polite close to make sure the message gets there.
-- Note: Object is delete when SP exits.  Seems to run the SP faster as well
exec sp_OAMethod @obj, 'Close', NULL
