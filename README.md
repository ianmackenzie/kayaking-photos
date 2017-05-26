This is a simple example of using CouchDB to host a searchable image database.
To get everything running you'll need to install CouchDB (it should
automatically start running once installed) and create a `kayaking-photos`
database using the CouchDB administration web app (available by default at
http://localhost:5984/_utils).

You can then load photos into the database by running
`pip install -r requirements.txt` in this directory to install the necessary
Python dependencies and then running `Python load_photos.py`. You'll need to use
Python 2 since the `iptcinfo` package doesn't support Python 3, and you'll need
to modify the script's `image_filenames` line to load your own photos. The
script is heavily commented so you can see what it's doing!

Then, create a `by_tag` 'view' in the database (again using the web admin
console) with the following JavaScript code:

```js
function (doc) {
  for (var i in doc.tags) {
    emit(doc.tags[i], null)
  }
}
```

This will result in a CouchDB 'view' (similar to an index in other databases)
that will contain one row for every tag of every image, sorted by tag to make
searching/filtering by tags easier.

Finally, [install Elm](https://guide.elm-lang.org/install.html), run
`elm package install` and then `elm reactor -p 9000` in this folder, and browse
to http://localhost:9000/Main.elm to view the interactive web app. Type tags
into the line edit to see matching photos (exact matches only right now).
`Main.elm` is also thoroughly commented!
