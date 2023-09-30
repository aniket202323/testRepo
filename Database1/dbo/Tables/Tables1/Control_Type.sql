CREATE TABLE [dbo].[Control_Type] (
    [Control_Type_Desc] VARCHAR (25) NOT NULL,
    [Control_Type_Id]   TINYINT      NOT NULL,
    CONSTRAINT [ControlType_PK_ControlTypeId] PRIMARY KEY CLUSTERED ([Control_Type_Id] ASC),
    CONSTRAINT [ControlType_UC_Control_Type_Desc] UNIQUE NONCLUSTERED ([Control_Type_Desc] ASC)
);

