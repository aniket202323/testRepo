CREATE TABLE [dbo].[Display_Option_Access] (
    [Display_Option_Access_Desc] VARCHAR (50) NOT NULL,
    [Display_Option_Access_Id]   INT          NOT NULL,
    CONSTRAINT [PK_Display_Option_Access] PRIMARY KEY NONCLUSTERED ([Display_Option_Access_Id] ASC),
    CONSTRAINT [Display_Option_Access_UC_Desc] UNIQUE NONCLUSTERED ([Display_Option_Access_Desc] ASC)
);

