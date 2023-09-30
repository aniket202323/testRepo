Create Procedure dbo.spEMFC_SearchFTPConfig
@str nvarchar(50),
@User_Id int
AS
select c.FTP_Engine, c.FC_Desc, a.FA_Desc, c.Mask, c.Local_Path, c.Remote_Path, c.FC_Id, c.is_active
from ftp_config c, FTP_Actions a
where FC_Desc like '%' + @str + '%' AND c.FA_Id = a.FA_Id
order by c.FTP_Engine
