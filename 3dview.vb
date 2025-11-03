Imports System.Web.Script.Serialization

Partial Class three3dview
    Inherits System.Web.UI.Page

    Public ArrowJson As String
    Public LabelJson As String

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim arrows = New List(Of Object) From {
            New With {.pos = New With {.x = 0, .y = 0.5, .z = 0},
                      .dir = New With {.x = 0, .y = 1, .z = 0},
                      .len = 2,
                      .color = &HFF3333,
                      .url = "https://example.com/a"},
            New With {.pos = New With {.x = 3, .y = 0.5, .z = 1},
                      .dir = New With {.x = 1, .y = 0, .z = 0},
                      .len = 2.5,
                      .color = &H33FF33,
                      .url = "https://example.com/b"},
            New With {.pos = New With {.x = -2, .y = 0.5, .z = -3},
                      .dir = New With {.x = 0, .y = 0, .z = -1},
                      .len = 1.5,
                      .color = &H3333FF,
                      .url = "https://example.com/c"}
        }

                                            ' === 建立文字標籤資料 ===
        Dim labels As New List(Of Object)

        labels.Add(New With {
            .text = "入口",
            .pos = New With {.x = 0, .y = 3, .z = 0},
            .color = "#00FF00",
            .size = 64
        })
        labels.Add(New With {
            .text = "電梯",
            .pos = New With {.x = 3, .y = 2.5, .z = 1},
            .color = "#FFFF00",
            .size = 48
        })
        labels.Add(New With {
            .text = "出口",
            .pos = New With {.x = -2, .y = 3, .z = -3},
            .color = "#FF5555",
            .size = 72
        })

        ' === 序列化成 JSON 給前端 ===
        Dim js As New JavaScriptSerializer()
        ArrowJson = js.Serialize(arrows)
        LabelJson = js.Serialize(labels)

     
    End Sub
End Class
