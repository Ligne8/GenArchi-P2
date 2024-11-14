import React, { useState, useEffect } from 'react';
import Navbar from './Navbar';

const API_GATEWAY_URL = "http://localhost:4000"

const Portfolio = () => {
    const [newMember, setNewMember] = useState({ name: '', role: '', image: '' });
    const [members, setMembers] = useState([]);

    // Appeler fetchMembers au montage du composant
    useEffect(() => {
        fetchMembers();
    }, []);

    const fetchMembers = async () => {
        const response = await fetch(API_GATEWAY_URL + '/members');
        const data = await response.json();
        console.log('Data from API:', data); // Inspectez cette structure
        setMembers(data.Items || data); // Utilise data.Items s'il existe, sinon data directement
    };

    const handleAddMember = async () => {
        console.log('New member:', newMember.name, newMember.role, newMember.image);
    
        // Vérifiez que newMember contient bien les données
        if (!newMember.name || !newMember.role || !newMember.image) {
            console.error('New member data is incomplete');
            return;
        }
    
        const response = await fetch(API_GATEWAY_URL + '/members', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: newMember.name,
                role: newMember.role,
                image: newMember.image
            })
        }).catch(error => console.error('Error:', error));
    
        if (response.ok) {
            const data = await response.json();
            console.log('Response from API:', data);
            setNewMember({ name: '', role: '', image: '' }); // Réinitialiser le formulaire
            fetchMembers(); // Recharger les membres
        } else {
            console.error('Failed to add member:', response.statusText);
        }
    };

    const handleDeleteMember = async (id) => {
        console.log("Member to delete:", id);
        const response = await fetch(API_GATEWAY_URL + '/members/' + id, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                Key: {
                    name: id
                },
            })
        }).catch(error => console.error('Error:', error)
        );
        const data = await response.json();
        console.log('Response from API delete:', data);
        fetchMembers(); // Recharger les membres après suppression
    };

    return (
        <>
            <Navbar />
            <div className="max-w-7xl mx-auto p-28 bg-gray-100">
                <h1 className="text-4xl font-bold text-center mb-4">Portfolio</h1>
                <h2 className="text-xl font-medium text-center text-gray-700 mb-6 max-w-2xl mx-auto mb-10">
                    Les membres de notre équipe
                </h2>
                <div className="mb-6 flex justify-center items-center">
                    <input
                        type="text"
                        placeholder="Name"
                        value={newMember.name}
                        onChange={(e) => setNewMember({ ...newMember, name: e.target.value })}
                        className="border p-2 mr-2"
                    />
                    <input
                        type="text"
                        placeholder="Role"
                        value={newMember.role}
                        onChange={(e) => setNewMember({ ...newMember, role: e.target.value })}
                        className="border p-2 mr-2"
                    />
                    <input
                        type="text"
                        placeholder="Image URL"
                        value={newMember.image}
                        onChange={(e) => setNewMember({ ...newMember, image: e.target.value })}
                        className="border p-2 mr-2"
                    />
                    <button onClick={handleAddMember} className="bg-blue-500 text-white p-2 rounded">
                        Add Member
                    </button>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
                    {members.map(member => (
                        <div key={member.name} className="bg-white p-4 rounded shadow">
                            <img src={member.image} alt={member.name} className="w-full h-48 object-cover rounded mb-4" />
                            <h3 className="text-xl font-bold">{member.name}</h3>
                            <p className="text-gray-700">{member.role}</p>
                            <button onClick={() => handleDeleteMember(member.name)} className="bg-red-500 text-white p-2 rounded mt-4">
                                Delete
                            </button>
                        </div>
                    ))}
                </div>
            </div>
        </>
    );
};

export default Portfolio;
