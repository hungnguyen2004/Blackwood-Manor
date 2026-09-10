param(
  [ValidateRange(1024, 65535)]
  [int]$Port = 8080
)

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$mime = @{ '.css'='text/css; charset=utf-8'; '.html'='text/html; charset=utf-8'; '.jpg'='image/jpeg'; '.js'='application/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8'; '.png'='image/png'; '.svg'='image/svg+xml' }

try {
  $listener.Start()
  Write-Host "Blackwood Manor is serving at http://localhost:$Port/Dinh-Thu-Blackwood.html"
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'Dinh-Thu-Blackwood.html' }
    $target = [IO.Path]::GetFullPath((Join-Path $root $relative.Replace('/', '\')))
    if (!$target.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $target -PathType Leaf)) {
      $context.Response.StatusCode = 404
      $context.Response.Close()
      continue
    }
    $bytes = [IO.File]::ReadAllBytes($target)
    $extension = [IO.Path]::GetExtension($target).ToLowerInvariant()
    $context.Response.ContentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
  }
} finally {
  $listener.Close()
}
