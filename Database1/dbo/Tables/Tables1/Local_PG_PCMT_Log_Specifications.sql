CREATE TABLE [dbo].[Local_PG_PCMT_Log_Specifications] (
    [Log_id]         INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]      DATETIME      NOT NULL,
    [User_id]        INT           NOT NULL,
    [Type]           VARCHAR (50)  NOT NULL,
    [Spec_Id]        INT           NULL,
    [Spec_Desc]      VARCHAR (50)  NULL,
    [Data_Type_Id]   INT           NULL,
    [Spec_Precision] INT           NULL,
    [Extended_Info]  VARCHAR (255) NULL
);

