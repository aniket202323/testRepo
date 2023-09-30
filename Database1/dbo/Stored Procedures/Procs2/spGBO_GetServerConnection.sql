Create Procedure dbo.spGBO_GetServerConnection 
  @ServiceDesc nvarchar(50), 
  @Listen_Port int_TCP_port OUTPUT,
  @Listen_Address nvarchar(15) OUTPUT    AS
  Select @Listen_Address = null
  Select @Listen_Address = listener_address, 
         @Listen_Port = listener_port 
  from Cxs_Service 
    where Service_Desc = @ServiceDesc
  if @Listen_Address is null 
    return(0)
  else
    return(100)
