﻿Create Procedure dbo.spEMCO_GetUserName
@UID int
AS
select Username from Users
where User_ID = @UID
