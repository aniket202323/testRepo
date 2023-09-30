CREATE TABLE [WorkOrder].[message] (
    [id]            VARCHAR (450)   NOT NULL,
    [destination]   NVARCHAR (1000) NOT NULL,
    [headers]       NVARCHAR (1000) NOT NULL,
    [payload]       NVARCHAR (MAX)  NOT NULL,
    [published]     SMALLINT        DEFAULT (CONVERT([smallint],(0))) NULL,
    [creation_time] BIGINT          DEFAULT (datediff_big(millisecond,'1970-01-01 00:00:00',getutcdate())) NULL,
    CONSTRAINT [PK_message] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [message_published_idx]
    ON [WorkOrder].[message]([published] ASC, [id] ASC);

