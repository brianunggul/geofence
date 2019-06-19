var geofences = require('./propertyGeofences.json');

function currentProperties(lat, long) {
    var list = [];

    if (userIsInVegas(lat, long)) {
        geofences["lvPropertyGeofences"].forEach(property => {
            if (lat >= property.latMinimum && lat <= property.latMaximum &&
                long >= property.longMinimum && long <= property.longMaximum) {
                    list.push(property.propertyId);
                }
        })
    }
    else {
        geofences["regionalPropertyGeofences"].forEach(property => {
            if (lat >= property.latMinimum && lat <= property.latMaximum &&
                long >= property.longMinimum && long <= property.longMaximum) {
                    list.push(property.propertyId);
                }
        })
    }
    
    return list[0];
}

function currentProperty(properties, lat, lon) {
    if (properties == []) return null;
   
    var list = geofences["lvPropertyGeofences"];
    var curr = null;
   
    for (var i = 0; i < properties.length; i++) {
       list.forEach(property => {
           if (property.propertyId == properties[i]) {
               if (lat >= property.latMinimum && lat <= property.latMaximum &&
                   lon >= property.longMinimum && lon <= property.longMaximum) {
                   curr = properties[i];
                   return curr;
               }
           }
       })
    }
    return curr;
}

function userIsInVegas(lat, long) {
    vegas = geofences["lasVegasGeofence"];
    return (lat >= vegas.latMinimum && lat <= vegas.latMaximum &&
            long >= vegas.longMinimum && long <= vegas.longMaximum);
}

console.log(currentProperties(30.392775, -88.893190));
console.log(userIsInVegas(30.392775, -88.893190));
geofences["lvPropertyGeofences"].forEach(property => {
    console.log(property.propertyId + ": " + property.centerLat + ", " + property.centerLong);
});