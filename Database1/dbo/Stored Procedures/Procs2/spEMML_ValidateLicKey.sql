CREATE PROCEDURE dbo.spEMML_ValidateLicKey
@LicenseKey nvarchar(500),
@User_Id int,
@ValidLicKey bit OUTPUT
AS
select @ValidLicKey = 1
-- Declare @License_Id int,
-- @License_Text nvarchar(500),
-- @License nvarchar(500)
-- 
-- select @ValidLicKey = 0
-- 
-- create table #Licenses(
-- License_Id int,
-- License_Text nvarchar(500),
-- License nvarchar(500) Null
-- )
-- insert into #Licenses
-- select License_Id, License_Text, Null from Licenses
-- 
-- Declare LicKeyCursor Cursor For
--   Select License_Id, License_Text from #Licenses for read only
-- Open LicKeyCursor
-- While (0=0) Begin
--   Fetch Next
--     From LicKeyCursor
--     Into @License_Id, @License_Text
--   If (@@Fetch_Status <> 0) Break
--     execute spCmn_Encryption @License_Text,'EncrYptoR',@License_Id,0,@License output
--     update #Licenses set License = @License
--     where License_Id = @License_Id
-- End
-- Close LicKeyCursor
-- Deallocate LicKeyCursor
-- 
-- select @License_Id = 0
-- 
-- select @License_Id = License_Id
-- from #Licenses
-- where License = @LicenseKey
-- 
-- if @License_Id = 0
--   select @ValidLicKey = 1
-- 
-- drop table #Licenses
